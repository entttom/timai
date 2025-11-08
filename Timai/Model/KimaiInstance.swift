//
//  KimaiInstance.swift
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
import KeychainAccess

/// Represents a Kimai instance with its configuration and credentials
struct KimaiInstance: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var apiEndpoint: URL
    var isActive: Bool
    
    init(id: UUID = UUID(), name: String, apiEndpoint: URL, isActive: Bool = false) {
        self.id = id
        self.name = name
        self.apiEndpoint = apiEndpoint
        self.isActive = isActive
    }
    
    // MARK: - Keychain Integration
    
    private var keychainKey: String {
        return "apiToken_\(id.uuidString)"
    }
    
    private var keychain: Keychain {
        return Keychain(service: Bundle.main.bundleIdentifier!)
    }
    
    /// Get the API token for this instance from the Keychain
    var apiToken: String? {
        get {
            do {
                return try keychain.get(keychainKey)
            } catch {
                print("❌ [KimaiInstance] Fehler beim Laden des API-Tokens für Instanz '\(name)': \(error)")
                return nil
            }
        }
    }
    
    /// Save the API token for this instance to the Keychain
    func saveToken(_ token: String) throws {
        do {
            try keychain.set(token, key: keychainKey)
            print("✅ [KimaiInstance] API-Token für Instanz '\(name)' gespeichert")
        } catch {
            print("❌ [KimaiInstance] Fehler beim Speichern des API-Tokens für Instanz '\(name)': \(error)")
            throw error
        }
    }
    
    /// Delete the API token for this instance from the Keychain
    func deleteToken() throws {
        do {
            try keychain.remove(keychainKey)
            print("✅ [KimaiInstance] API-Token für Instanz '\(name)' gelöscht")
        } catch {
            print("❌ [KimaiInstance] Fehler beim Löschen des API-Tokens für Instanz '\(name)': \(error)")
            throw error
        }
    }
    
    // MARK: - Equatable
    
    static func == (lhs: KimaiInstance, rhs: KimaiInstance) -> Bool {
        return lhs.id == rhs.id
    }
}


