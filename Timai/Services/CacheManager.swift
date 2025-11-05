//
//  CacheManager.swift
//  Timai
//
//  Copyright (c) 2025 Dr. Thomas Entner.
//  All rights reserved.
//
//  Licensed under the Business Source License 1.1.
//  Usage is free for non-commercial and personal use.
//  Commercial use requires a commercial license.
//
import Foundation

@MainActor
class CacheManager: ObservableObject {
    static let shared = CacheManager()
    
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var cacheSize: Int64 = 0
    
    private let fileManager = FileManager.default
    private var cacheDirectory: URL?
    
    enum CacheType: String {
        case timesheets
        case customers
        case projects
        case activities
        case users
        case projectsForCustomer // Format: projects_customerId
        case activitiesForProject // Format: activities_projectId
    }
    
    struct CacheMetadata: Codable {
        let timestamp: Date
        let userEndpoint: String
        let dataType: String
    }
    
    private init() {
        setupCacheDirectory()
        calculateCacheSize()
        print("💾 [CacheManager] Initialisiert - Cache-Verzeichnis: \(cacheDirectory?.path ?? "none")")
    }
    
    // MARK: - Setup
    
    private func setupCacheDirectory() {
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("❌ [CacheManager] Konnte Documents-Verzeichnis nicht finden")
            return
        }
        
        cacheDirectory = documentsPath.appendingPathComponent("cache", isDirectory: true)
        
        if let cacheDir = cacheDirectory, !fileManager.fileExists(atPath: cacheDir.path) {
            do {
                try fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
                print("✅ [CacheManager] Cache-Verzeichnis erstellt: \(cacheDir.path)")
            } catch {
                print("❌ [CacheManager] Fehler beim Erstellen des Cache-Verzeichnisses: \(error)")
            }
        }
    }
    
    private func getCacheURL(for user: User, type: CacheType, identifier: String? = nil) -> URL? {
        guard let cacheDir = cacheDirectory else { return nil }
        
        // Create user-specific subdirectory based on endpoint hash
        let endpointHash = user.apiEndpoint.absoluteString.hash
        let userDir = cacheDir.appendingPathComponent("user_\(endpointHash)", isDirectory: true)
        
        // Create directory if needed
        if !fileManager.fileExists(atPath: userDir.path) {
            try? fileManager.createDirectory(at: userDir, withIntermediateDirectories: true)
        }
        
        // Build filename
        var filename = type.rawValue
        if let id = identifier {
            filename += "_\(id)"
        }
        filename += ".json"
        
        return userDir.appendingPathComponent(filename)
    }
    
    // MARK: - Cache Operations
    
    func cache<T: Codable>(_ data: T, for user: User, type: CacheType, identifier: String? = nil) async throws {
        guard let url = getCacheURL(for: user, type: type, identifier: identifier) else {
            throw CacheError.invalidPath
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encodedData = try encoder.encode(data)
        
        try encodedData.write(to: url)
        
        // Update metadata
        let metadata = CacheMetadata(
            timestamp: Date(),
            userEndpoint: user.apiEndpoint.absoluteString,
            dataType: type.rawValue
        )
        try cacheMetadata(metadata, at: url)
        
        lastSyncDate = Date()
        await calculateCacheSize()
        
        print("💾 [CacheManager] Gecacht: \(type.rawValue)\(identifier.map { "_\($0)" } ?? "") - \(encodedData.count) bytes")
    }
    
    func load<T: Codable>(_ type: T.Type, for user: User, cacheType: CacheType, identifier: String? = nil) async throws -> T {
        guard let url = getCacheURL(for: user, type: cacheType, identifier: identifier) else {
            throw CacheError.invalidPath
        }
        
        guard fileManager.fileExists(atPath: url.path) else {
            print("⚠️ [CacheManager] Kein Cache gefunden für: \(cacheType.rawValue)")
            throw CacheError.notFound
        }
        
        // Check if cache is too old
        if let metadata = try? loadMetadata(at: url) {
            let maxCacheAge = UserDefaults.standard.integer(forKey: "cacheRetentionDays")
            let effectiveMaxAge = maxCacheAge > 0 ? maxCacheAge : 30
            
            if let daysSinceCache = Calendar.current.dateComponents([.day], from: metadata.timestamp, to: Date()).day,
               daysSinceCache > effectiveMaxAge {
                print("⚠️ [CacheManager] Cache zu alt (\(daysSinceCache) Tage): \(cacheType.rawValue)")
                throw CacheError.expired
            }
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(T.self, from: data)
        
        print("💾 [CacheManager] Aus Cache geladen: \(cacheType.rawValue)\(identifier.map { "_\($0)" } ?? "") - \(data.count) bytes")
        return decoded
    }
    
    func clearCache(for user: User) async throws {
        guard let cacheDir = cacheDirectory else { return }
        
        let endpointHash = user.apiEndpoint.absoluteString.hash
        let userDir = cacheDir.appendingPathComponent("user_\(endpointHash)", isDirectory: true)
        
        if fileManager.fileExists(atPath: userDir.path) {
            try fileManager.removeItem(at: userDir)
            print("🗑️ [CacheManager] Cache für User gelöscht")
            calculateCacheSize()
        }
    }
    
    func clearAllCache() async throws {
        guard let cacheDir = cacheDirectory else { return }
        
        if fileManager.fileExists(atPath: cacheDir.path) {
            try fileManager.removeItem(at: cacheDir)
            setupCacheDirectory()
            print("🗑️ [CacheManager] Gesamter Cache gelöscht")
            calculateCacheSize()
            lastSyncDate = nil
        }
    }
    
    // MARK: - Metadata
    
    private func cacheMetadata(_ metadata: CacheMetadata, at url: URL) throws {
        let metadataURL = url.deletingPathExtension().appendingPathExtension("meta.json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(metadata)
        try data.write(to: metadataURL)
    }
    
    private func loadMetadata(at url: URL) throws -> CacheMetadata {
        let metadataURL = url.deletingPathExtension().appendingPathExtension("meta.json")
        let data = try Data(contentsOf: metadataURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(CacheMetadata.self, from: data)
    }
    
    // MARK: - Cache Statistics
    
    func calculateCacheSize() {
        Task {
            guard let cacheDir = cacheDirectory else {
                self.cacheSize = 0
                return
            }
            
            var totalSize: Int64 = 0
            
            if let enumerator = fileManager.enumerator(at: cacheDir, includingPropertiesForKeys: [.fileSizeKey]) {
                for case let fileURL as URL in enumerator {
                    if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                       let fileSize = resourceValues.fileSize {
                        totalSize += Int64(fileSize)
                    }
                }
            }
            
            self.cacheSize = totalSize
        }
    }
    
    func getCacheStatistics(for user: User) -> CacheStatistics {
        guard let cacheDir = cacheDirectory else {
            return CacheStatistics(timesheetsCount: 0, customersCount: 0, projectsCount: 0, activitiesCount: 0)
        }
        
        let endpointHash = user.apiEndpoint.absoluteString.hash
        let userDir = cacheDir.appendingPathComponent("user_\(endpointHash)", isDirectory: true)
        
        var stats = CacheStatistics(timesheetsCount: 0, customersCount: 0, projectsCount: 0, activitiesCount: 0)
        
        // Count timesheets
        if let timesheets = try? loadTimesheetsSync(for: user) {
            stats.timesheetsCount = timesheets.count
        }
        
        // Count customers
        if let customers = try? loadCustomersSync(for: user) {
            stats.customersCount = customers.count
        }
        
        return stats
    }
    
    // MARK: - Convenience Methods
    
    private func loadTimesheetsSync(for user: User) throws -> [Timesheet] {
        guard let url = getCacheURL(for: user, type: .timesheets) else {
            throw CacheError.invalidPath
        }
        
        guard fileManager.fileExists(atPath: url.path) else {
            return []
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Timesheet].self, from: data)
    }
    
    private func loadCustomersSync(for user: User) throws -> [Customer] {
        guard let url = getCacheURL(for: user, type: .customers) else {
            throw CacheError.invalidPath
        }
        
        guard fileManager.fileExists(atPath: url.path) else {
            return []
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Customer].self, from: data)
    }
    
    // MARK: - Errors
    
    enum CacheError: Error, LocalizedError {
        case invalidPath
        case notFound
        case expired
        
        var errorDescription: String? {
            switch self {
            case .invalidPath:
                return "Ungültiger Cache-Pfad"
            case .notFound:
                return "Cache nicht gefunden"
            case .expired:
                return "Cache ist abgelaufen"
            }
        }
    }
}

// MARK: - Cache Statistics
struct CacheStatistics {
    var timesheetsCount: Int
    var customersCount: Int
    var projectsCount: Int
    var activitiesCount: Int
}


