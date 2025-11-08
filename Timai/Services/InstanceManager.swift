//
//  InstanceManager.swift
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
import Combine

/// Manager for handling multiple Kimai instances
@MainActor
class InstanceManager: ObservableObject {
    static let shared = InstanceManager()
    
    @Published private(set) var instances: [KimaiInstance] = []
    @Published private(set) var activeInstance: KimaiInstance?
    
    private let userDefaultsKey = "kimaiInstances"
    private let activeInstanceKey = "activeInstanceId"
    
    private init() {
        loadInstances()
        print("🏢 [InstanceManager] Initialisiert mit \(instances.count) Instanz(en)")
    }
    
    // MARK: - Load & Save
    
    /// Load all instances from UserDefaults
    private func loadInstances() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            print("ℹ️ [InstanceManager] Keine gespeicherten Instanzen gefunden")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            instances = try decoder.decode([KimaiInstance].self, from: data)
            print("✅ [InstanceManager] \(instances.count) Instanz(en) geladen")
            
            // Load active instance
            if let activeId = UserDefaults.standard.string(forKey: activeInstanceKey),
               let uuid = UUID(uuidString: activeId),
               let active = instances.first(where: { $0.id == uuid }) {
                activeInstance = active
                print("✅ [InstanceManager] Aktive Instanz: '\(active.name)'")
            } else if let first = instances.first {
                // Fallback: Set first instance as active
                activeInstance = first
                print("ℹ️ [InstanceManager] Keine aktive Instanz gefunden, verwende erste: '\(first.name)'")
            }
        } catch {
            print("❌ [InstanceManager] Fehler beim Laden der Instanzen: \(error)")
        }
    }
    
    /// Save all instances to UserDefaults
    private func saveInstances() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(instances)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            print("💾 [InstanceManager] \(instances.count) Instanz(en) gespeichert")
        } catch {
            print("❌ [InstanceManager] Fehler beim Speichern der Instanzen: \(error)")
        }
    }
    
    /// Save active instance ID
    private func saveActiveInstance() {
        if let active = activeInstance {
            UserDefaults.standard.set(active.id.uuidString, forKey: activeInstanceKey)
            print("💾 [InstanceManager] Aktive Instanz gespeichert: '\(active.name)'")
        } else {
            UserDefaults.standard.removeObject(forKey: activeInstanceKey)
            print("💾 [InstanceManager] Keine aktive Instanz mehr")
        }
    }
    
    // MARK: - CRUD Operations
    
    /// Add a new instance
    func addInstance(_ instance: KimaiInstance) {
        var newInstance = instance
        
        // If this is the first instance, make it active
        if instances.isEmpty {
            newInstance.isActive = true
            activeInstance = newInstance
            instances.append(newInstance)
            saveInstances()
            saveActiveInstance()
        } else {
            // Not the first instance - add as inactive
            newInstance.isActive = false
            instances.append(newInstance)
            saveInstances()
        }
        
        print("➕ [InstanceManager] Instanz hinzugefügt: '\(newInstance.name)' (active: \(newInstance.isActive))")
    }
    
    /// Update an existing instance
    func updateInstance(_ instance: KimaiInstance) {
        guard let index = instances.firstIndex(where: { $0.id == instance.id }) else {
            print("⚠️ [InstanceManager] Instanz nicht gefunden: '\(instance.name)'")
            return
        }
        
        instances[index] = instance
        
        // Update active instance if it's the one being updated
        if activeInstance?.id == instance.id {
            activeInstance = instance
        }
        
        saveInstances()
        print("✏️ [InstanceManager] Instanz aktualisiert: '\(instance.name)'")
    }
    
    /// Delete an instance
    func deleteInstance(_ instance: KimaiInstance) async throws {
        guard let index = instances.firstIndex(where: { $0.id == instance.id }) else {
            print("⚠️ [InstanceManager] Instanz nicht gefunden: '\(instance.name)'")
            return
        }
        
        // Delete token from keychain
        try instance.deleteToken()
        
        // Delete cache for this instance
        let user = User(apiEndpoint: instance.apiEndpoint, apiToken: nil)
        try await CacheManager.shared.clearCache(for: user)
        
        // Remove from list
        instances.remove(at: index)
        
        // If this was the active instance, set another one as active
        if activeInstance?.id == instance.id {
            activeInstance = instances.first
            if let newActive = activeInstance {
                var updatedInstance = newActive
                updatedInstance.isActive = true
                updateInstance(updatedInstance)
            }
            saveActiveInstance()
        }
        
        saveInstances()
        print("🗑️ [InstanceManager] Instanz gelöscht: '\(instance.name)'")
    }
    
    /// Switch to a different instance
    func switchToInstance(_ instance: KimaiInstance) {
        guard instances.contains(where: { $0.id == instance.id }) else {
            print("⚠️ [InstanceManager] Instanz nicht in Liste gefunden: '\(instance.name)'")
            return
        }
        
        // Deactivate all instances
        for i in 0..<instances.count {
            instances[i].isActive = false
        }
        
        // Activate selected instance
        if let index = instances.firstIndex(where: { $0.id == instance.id }) {
            instances[index].isActive = true
            activeInstance = instances[index]
        }
        
        saveInstances()
        saveActiveInstance()
        
        // Notify observers about instance change
        NotificationCenter.default.post(name: .instanceDidChange, object: instance)
        
        print("🔄 [InstanceManager] Gewechselt zu Instanz: '\(instance.name)'")
    }
    
    // MARK: - Helpers
    
    /// Check if there are multiple instances
    var hasMultipleInstances: Bool {
        return instances.count > 1
    }
    
    /// Get instance by ID
    func getInstance(id: UUID) -> KimaiInstance? {
        return instances.first(where: { $0.id == id })
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let instanceDidChange = Notification.Name("instanceDidChange")
}

