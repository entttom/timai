//
//  PendingOperationsManager.swift
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
class PendingOperationsManager: ObservableObject {
    static let shared = PendingOperationsManager()
    
    @Published private(set) var pendingOperations: [PendingOperationItem] = []
    @Published private(set) var failedOperations: [PendingOperationItem] = []
    
    private let fileManager = FileManager.default
    private var queueURL: URL?
    private let maxRetries = 3
    
    // Temp ID to Server ID mapping
    private var tempIdMapping: [String: Int] = [:]
    
    // Temp ID to Hash mapping (for UI matching)
    private var tempIdToHash: [String: Int] = [:]
    
    var hasPendingOperations: Bool {
        !pendingOperations.isEmpty
    }
    
    var pendingCount: Int {
        pendingOperations.count
    }
    
    private init() {
        setupQueueDirectory()
        loadQueue()
    }
    
    // MARK: - Setup
    
    private func setupQueueDirectory() {
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let queueDir = documentsPath.appendingPathComponent("pending_operations", isDirectory: true)
        
        if !fileManager.fileExists(atPath: queueDir.path) {
            try? fileManager.createDirectory(at: queueDir, withIntermediateDirectories: true)
        }
        
        queueURL = queueDir.appendingPathComponent("queue.json")
    }
    
    // MARK: - Queue Management
    
    func addOperation(_ operation: PendingOperation) {
        // Calculate hash for CREATE operations
        var itemHash: Int? = nil
        if case .createTimesheet(_, let tempId) = operation {
            let hash = -(abs(tempId.hashValue) % 1_000_000)
            tempIdToHash[tempId] = hash
            itemHash = hash
        }
        
        let item = PendingOperationItem(operation: operation, tempIdHash: itemHash)
        pendingOperations.append(item)
        
        saveQueue()
        
        // Force UI update
        objectWillChange.send()
    }
    
    func removeOperation(_ item: PendingOperationItem) {
        pendingOperations.removeAll { $0.id == item.id }
        saveQueue()
    }
    
    func markAsCompleted(_ item: PendingOperationItem, serverId: Int? = nil) {
        if let index = pendingOperations.firstIndex(where: { $0.id == item.id }) {
            var updated = pendingOperations[index]
            updated.status = .completed
            
            // Store temp ID mapping if this was a create operation
            if let tempId = item.operation.tempId, let serverId = serverId {
                tempIdMapping[tempId] = serverId
            }
            
            pendingOperations.remove(at: index)
            saveQueue()
        }
    }
    
    func markAsFailed(_ item: PendingOperationItem, error: String) {
        if let index = pendingOperations.firstIndex(where: { $0.id == item.id }) {
            var updated = pendingOperations[index]
            updated.retryCount += 1
            updated.lastError = error
            
            if updated.retryCount >= maxRetries {
                updated.status = .failed
                pendingOperations.remove(at: index)
                failedOperations.append(updated)
            } else {
                updated.status = .pending
                pendingOperations[index] = updated
            }
            
            saveQueue()
        }
    }
    
    func markAsSyncing(_ item: PendingOperationItem) {
        if let index = pendingOperations.firstIndex(where: { $0.id == item.id }) {
            pendingOperations[index].status = .syncing
        }
    }
    
    /// Update all pending operations that reference a temp ID with the real server ID
    func updateOperationsWithTempId(_ tempId: Int, newId: Int) {
        var updated = false
        
        for (index, var item) in pendingOperations.enumerated() {
            switch item.operation {
            case .updateTimesheet(let id, let form):
                if id == tempId {
                    item.operation = .updateTimesheet(id: newId, form: form)
                    pendingOperations[index] = item
                    updated = true
                }
            case .deleteTimesheet(let id):
                if id == tempId {
                    item.operation = .deleteTimesheet(id: newId)
                    pendingOperations[index] = item
                    updated = true
                }
            case .createTimesheet:
                // CREATE operations don't need updating
                break
            }
        }
        
        if updated {
            saveQueue()
        }
    }
    
    /// Find and update a pending CREATE operation for a timer (without end date) to include the end date
    /// Returns the tempId hash if an operation was found and updated, nil otherwise
    func updatePendingTimerCreateOperation(projectId: Int, activityId: Int, beginDate: Date, endDate: Date, description: String?) -> Int? {
        let beginString = beginDate.ISO8601Format()
        let endString = endDate.ISO8601Format()
        let formatter = ISO8601DateFormatter()
        
        for (index, var item) in pendingOperations.enumerated() {
            if case .createTimesheet(let form, let tempId) = item.operation {
                // Check if this CREATE operation matches the timer:
                // - Same project and activity
                // - Same begin date (with tolerance for small differences)
                // - No end date (running timer)
                if form.project == projectId,
                   form.activity == activityId,
                   form.end == nil {
                    // Compare begin dates with tolerance (within 5 seconds)
                    var beginMatches = false
                    if let formBegin = form.begin {
                        if formBegin == beginString {
                            beginMatches = true
                        } else if let formBeginDate = formatter.date(from: formBegin) {
                            // Allow small differences (e.g., due to rounding or timezone)
                            let timeDifference = abs(formBeginDate.timeIntervalSince(beginDate))
                            if timeDifference < 5.0 { // 5 seconds tolerance
                                beginMatches = true
                            }
                        }
                    }
                    
                    if beginMatches {
                        // Update the form to include the end date
                        let updatedForm = TimesheetEditForm(
                            project: form.project,
                            activity: form.activity,
                            begin: form.begin, // Keep original begin date from form
                            end: endString,
                            description: description ?? form.description,
                            tags: form.tags,
                            fixedRate: form.fixedRate,
                            hourlyRate: form.hourlyRate,
                            user: form.user,
                            exported: form.exported,
                            billable: form.billable
                        )
                        
                        item.operation = .createTimesheet(form: updatedForm, tempId: tempId)
                        pendingOperations[index] = item
                        saveQueue()
                        
                        // Return the temp ID hash for cache update
                        let hash = item.tempIdHash ?? -(abs(tempId.hashValue) % 1_000_000)
                        return hash
                    }
                }
            }
        }
        
        return nil
    }
    
    func retryFailedOperation(_ item: PendingOperationItem) {
        if let index = failedOperations.firstIndex(where: { $0.id == item.id }) {
            var updated = failedOperations[index]
            updated.status = .pending
            updated.retryCount = 0
            updated.lastError = nil
            
            failedOperations.remove(at: index)
            pendingOperations.append(updated)
            saveQueue()
        }
    }
    
    func discardFailedOperation(_ item: PendingOperationItem) {
        failedOperations.removeAll { $0.id == item.id }
        saveQueue()
    }
    
    func clearAllOperations() {
        pendingOperations.removeAll()
        failedOperations.removeAll()
        tempIdMapping.removeAll()
        saveQueue()
    }
    
    // MARK: - Temp ID Mapping
    
    func getServerId(for tempId: String) -> Int? {
        return tempIdMapping[tempId]
    }
    
    func getTempIdHash(for tempId: String) -> Int? {
        return tempIdToHash[tempId]
    }
    
    func hasPendingOperationForId(_ id: Int) -> Bool {
        return pendingOperations.contains { item in
            // For CREATE operations, use the stored hash
            if case .createTimesheet(_, let tempId) = item.operation {
                // Try stored hash first, then calculate
                let hash = item.tempIdHash ?? -(abs(tempId.hashValue) % 1_000_000)
                return hash == id
            }
            
            // For UPDATE and DELETE, compare IDs directly
            switch item.operation {
            case .updateTimesheet(let opId, _):
                return opId == id
            case .deleteTimesheet(let opId):
                return opId == id
            default:
                return false
            }
        }
    }
    
    // MARK: - Persistence
    
    private func saveQueue() {
        guard let url = queueURL else { return }
        
        let data = QueueData(
            pending: pendingOperations,
            failed: failedOperations,
            tempIdMapping: tempIdMapping,
            tempIdToHash: tempIdToHash
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let encoded = try encoder.encode(data)
            try encoded.write(to: url)
        } catch {
            // Fehler beim Speichern - ignorieren
        }
    }
    
    private func loadQueue() {
        guard let url = queueURL, fileManager.fileExists(atPath: url.path) else {
            return
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let data = try Data(contentsOf: url)
            let queueData = try decoder.decode(QueueData.self, from: data)
            pendingOperations = queueData.pending
            failedOperations = queueData.failed
            tempIdMapping = queueData.tempIdMapping
            tempIdToHash = queueData.tempIdToHash ?? [:]
            
            // Rebuild hash mappings and update items if missing (for backward compatibility)
            var needsSave = false
            for (index, var item) in pendingOperations.enumerated() {
                if case .createTimesheet(_, let tempId) = item.operation {
                    let hash = -(abs(tempId.hashValue) % 1_000_000)
                    
                    // Store in tempIdToHash map
                    if tempIdToHash[tempId] == nil {
                        tempIdToHash[tempId] = hash
                        needsSave = true
                    }
                    
                    // Update item with hash if missing
                    if item.tempIdHash == nil {
                        item.tempIdHash = hash
                        pendingOperations[index] = item
                        needsSave = true
                    }
                }
            }
            
            // Save updated queue with hash mappings
            if needsSave {
                saveQueue()
            }
        } catch {
            // Lösche die alte Queue, da sie ein inkompatibles Format hat
            // (z.B. tags als Array statt String)
            if let url = queueURL {
                try? fileManager.removeItem(at: url)
            }
        }
    }
    
    // MARK: - Helper Structures
    
    private struct QueueData: Codable {
        let pending: [PendingOperationItem]
        let failed: [PendingOperationItem]
        let tempIdMapping: [String: Int]
        let tempIdToHash: [String: Int]?
    }
}


