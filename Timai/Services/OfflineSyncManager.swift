//
//  OfflineSyncManager.swift
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

@MainActor
class OfflineSyncManager: ObservableObject {
    static let shared = OfflineSyncManager()
    
    @Published private(set) var syncStatus: SyncStatus = .idle
    @Published private(set) var lastSyncDate: Date?
    
    private let networkMonitor = NetworkMonitor.shared
    private let pendingOpsManager = PendingOperationsManager.shared
    private let networkService = NetworkService.shared
    
    private var cancellables = Set<AnyCancellable>()
    private var isSyncing = false
    
    private init() {
        setupNetworkMonitoring()
        loadLastSyncDate()
        print("🔄 [OfflineSyncManager] Initialisiert")
    }
    
    // MARK: - Setup
    
    private func setupNetworkMonitoring() {
        // Listen for network connection restoration
        NotificationCenter.default.publisher(for: .networkConnectionRestored)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.onNetworkRestored()
                }
            }
            .store(in: &cancellables)
        
        print("🔄 [OfflineSyncManager] Netzwerk-Monitoring aktiv")
    }
    
    private func onNetworkRestored() async {
        print("✅ [OfflineSyncManager] Netzwerk wiederhergestellt - starte Auto-Sync")
        
        // Check if auto-sync is enabled
        let autoSyncEnabled = UserDefaults.standard.bool(forKey: "autoSyncEnabled")
        if autoSyncEnabled || UserDefaults.standard.object(forKey: "autoSyncEnabled") == nil {
            await syncPendingOperations()
        }
    }
    
    // MARK: - Sync Operations
    
    func syncPendingOperations(for user: User? = nil) async {
        guard !isSyncing else {
            print("⚠️ [OfflineSyncManager] Sync läuft bereits")
            return
        }
        
        guard networkMonitor.isConnected else {
            print("⚠️ [OfflineSyncManager] Keine Netzwerkverbindung - Sync abgebrochen")
            syncStatus = .failed(error: "Keine Netzwerkverbindung")
            return
        }
        
        guard pendingOpsManager.hasPendingOperations else {
            print("ℹ️ [OfflineSyncManager] Keine ausstehenden Operationen")
            syncStatus = .idle
            return
        }
        
        // Get current user if not provided
        guard let currentUser = user else {
            print("⚠️ [OfflineSyncManager] Kein User verfügbar")
            return
        }
        
        isSyncing = true
        syncStatus = .syncing(progress: 0.0)
        print("🔄 [OfflineSyncManager] Starte Synchronisierung von \(pendingOpsManager.pendingCount) Operationen")
        
        let operations = pendingOpsManager.pendingOperations
        let totalOps = operations.count
        
        for (index, item) in operations.enumerated() {
            let progress = Double(index) / Double(totalOps)
            syncStatus = .syncing(progress: progress)
            
            pendingOpsManager.markAsSyncing(item)
            
            do {
                try await syncOperation(item, user: currentUser)
                pendingOpsManager.markAsCompleted(item, serverId: nil)
                print("✅ [OfflineSyncManager] Operation synchronisiert: \(item.operation.description)")
            } catch {
                print("❌ [OfflineSyncManager] Fehler beim Sync: \(error.localizedDescription)")
                pendingOpsManager.markAsFailed(item, error: error.localizedDescription)
            }
            
            // Small delay between operations
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        isSyncing = false
        
        if pendingOpsManager.hasPendingOperations {
            syncStatus = .failed(error: "Einige Operationen konnten nicht synchronisiert werden")
        } else {
            syncStatus = .completed
            lastSyncDate = Date()
            saveLastSyncDate()
            print("✅ [OfflineSyncManager] Synchronisierung erfolgreich abgeschlossen")
            
            // Notify that sync completed
            NotificationCenter.default.post(name: .syncCompleted, object: nil)
            
            // Reset to idle after a short delay
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            if syncStatus == .completed {
                syncStatus = .idle
            }
        }
    }
    
    private func syncOperation(_ item: PendingOperationItem, user: User) async throws {
        switch item.operation {
        case .createTimesheet(let form, let tempId):
            let timesheet = try await networkService.createTimesheet(form: form, user: user)
            
            // Get temp hash for matching
            let tempHash = item.tempIdHash ?? -(abs(tempId.hashValue) % 1_000_000)
            
            // Update all pending UPDATE/DELETE operations that reference this temp ID
            pendingOpsManager.updateOperationsWithTempId(tempHash, newId: timesheet.id)
            
            // Store temp ID mapping
            pendingOpsManager.markAsCompleted(item, serverId: timesheet.id)
            print("✅ [OfflineSyncManager] Timesheet erstellt - Temp ID: \(tempId) (hash: \(tempHash)) -> Server ID: \(timesheet.id)")
            
        case .updateTimesheet(let id, let form):
            // Check if this is a negative (temp) ID
            if id < 0 {
                // Check if there's a CREATE operation for this temp ID
                let hasCreateOp = pendingOpsManager.pendingOperations.contains { item in
                    if case .createTimesheet(_, _) = item.operation, item.tempIdHash == id {
                        return true
                    }
                    return false
                }
                
                if hasCreateOp {
                    // CREATE will be synced first, then this UPDATE will be updated
                    print("⚠️ [OfflineSyncManager] UPDATE mit negativer ID: \(id) - warte auf CREATE Sync")
                    throw NSError(domain: "OfflineSync", code: 404, userInfo: [NSLocalizedDescriptionKey: "Negative ID - CREATE Operation noch nicht synchronisiert"])
                } else {
                    // CREATE was already synced in a previous session - this UPDATE is orphaned
                    print("⚠️ [OfflineSyncManager] Verwaiste UPDATE-Operation mit negativer ID: \(id) - CREATE wurde bereits synchronisiert, lösche Operation")
                    pendingOpsManager.markAsCompleted(item)
                    return
                }
            }
            
            _ = try await networkService.updateTimesheet(id: id, form: form, user: user)
            pendingOpsManager.markAsCompleted(item)
            print("✅ [OfflineSyncManager] Timesheet aktualisiert - ID: \(id)")
            
        case .deleteTimesheet(let id):
            // Check if this is a negative (temp) ID
            if id < 0 {
                // Check if there's a CREATE operation for this temp ID
                let hasCreateOp = pendingOpsManager.pendingOperations.contains { item in
                    if case .createTimesheet(_, _) = item.operation, item.tempIdHash == id {
                        return true
                    }
                    return false
                }
                
                if hasCreateOp {
                    // CREATE will be synced first, then this DELETE will be updated
                    print("⚠️ [OfflineSyncManager] DELETE mit negativer ID: \(id) - warte auf CREATE Sync")
                    throw NSError(domain: "OfflineSync", code: 404, userInfo: [NSLocalizedDescriptionKey: "Negative ID - CREATE Operation noch nicht synchronisiert"])
                } else {
                    // CREATE was already synced in a previous session - this DELETE is orphaned
                    print("⚠️ [OfflineSyncManager] Verwaiste DELETE-Operation mit negativer ID: \(id) - CREATE wurde bereits synchronisiert, lösche Operation")
                    pendingOpsManager.markAsCompleted(item)
                    return
                }
            }
            
            try await networkService.deleteTimesheet(id: id, user: user)
            pendingOpsManager.markAsCompleted(item)
            print("✅ [OfflineSyncManager] Timesheet gelöscht - ID: \(id)")
        }
    }
    
    // MARK: - Manual Sync Trigger
    
    func triggerManualSync(for user: User) async {
        print("🔄 [OfflineSyncManager] Manueller Sync ausgelöst")
        await syncPendingOperations(for: user)
    }
    
    // MARK: - Persistence
    
    private func saveLastSyncDate() {
        if let date = lastSyncDate {
            UserDefaults.standard.set(date, forKey: "lastSyncDate")
        }
    }
    
    private func loadLastSyncDate() {
        lastSyncDate = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date
    }
}


