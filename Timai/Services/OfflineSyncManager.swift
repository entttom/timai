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
    private let instanceManager = InstanceManager.shared
    
    private var cancellables = Set<AnyCancellable>()
    private var isSyncing = false
    
    private init() {
        setupNetworkMonitoring()
        loadLastSyncDate()
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
    }
    
    private func onNetworkRestored() async {
        // Check if auto-sync is enabled
        let autoSyncEnabled = UserDefaults.standard.bool(forKey: "autoSyncEnabled")
        if autoSyncEnabled || UserDefaults.standard.object(forKey: "autoSyncEnabled") == nil {
            // Get current user from InstanceManager (similar to AuthViewModel)
            guard let activeInstance = instanceManager.activeInstance,
                  let apiToken = activeInstance.apiToken else {
                return
            }
            
            let user = User(
                apiEndpoint: activeInstance.apiEndpoint,
                apiToken: apiToken,
                instanceId: activeInstance.id
            )
            
            await syncPendingOperations(for: user)
        }
    }
    
    // MARK: - Sync Operations
    
    func syncPendingOperations(for user: User? = nil) async {
        guard !isSyncing else {
            return
        }
        
        guard networkMonitor.isConnected else {
            syncStatus = .failed(error: "Keine Netzwerkverbindung")
            return
        }
        
        guard pendingOpsManager.hasPendingOperations else {
            syncStatus = .idle
            return
        }
        
        // Get current user if not provided
        guard let currentUser = user else {
            return
        }
        
        isSyncing = true
        syncStatus = .syncing(progress: 0.0)
        
        let operations = pendingOpsManager.pendingOperations
        let totalOps = operations.count
        
        for (index, item) in operations.enumerated() {
            let progress = Double(index) / Double(totalOps)
            syncStatus = .syncing(progress: progress)
            
            pendingOpsManager.markAsSyncing(item)
            
            do {
                try await syncOperation(item, user: currentUser)
                // Note: markAsCompleted is already called in syncOperation for CREATE operations
                // Only call it here for other operation types that don't call it themselves
                if case .createTimesheet = item.operation {
                    // Already marked as completed in syncOperation with serverId
                } else {
                    pendingOpsManager.markAsCompleted(item, serverId: nil)
                }
            } catch let error as NetworkService.APIError {
                // Validierungsfehler sollten nicht wiederholt werden - entferne die Operation
                if case .validationError(let message) = error {
                    // Post notification about validation error
                    let errorInfo: [String: Any] = [
                        "operation": item.operation.description,
                        "error": message
                    ]
                    NotificationCenter.default.post(
                        name: .syncValidationError,
                        object: nil,
                        userInfo: errorInfo
                    )
                    
                    pendingOpsManager.markAsCompleted(item) // Als "abgeschlossen" markieren, um sie zu entfernen
                } else {
                    pendingOpsManager.markAsFailed(item, error: error.localizedDescription)
                }
            } catch {
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
            // Stelle sicher, dass alle Tags existieren, bevor wir das Timesheet erstellen
            try await ensureTagsExist(form: form, user: user)
            
            // Prüfe, ob die Activity noch gültig ist (mit Timeout, um nicht zu hängen)
            var validatedForm = form
            
            // Versuche Activity-Validierung mit Timeout (3 Sekunden)
            // Wenn die Validierung zu lange dauert oder fehlschlägt, verwenden wir die ursprüngliche Activity
            do {
                let activities = try await withTimeout(seconds: 3) {
                    try await self.networkService.getActivities(projectId: form.project, user: user)
                }
                
                if activities.isEmpty {
                    // Keine Activities gefunden - verwende ursprüngliche Activity
                } else {
                    let activityExists = activities.contains(where: { $0.id == form.activity })
                    
                    if !activityExists {
                        // Verwende die erste verfügbare Activity für das Projekt
                        if let firstActivity = activities.first {
                            validatedForm = TimesheetEditForm(
                                project: form.project,
                                activity: firstActivity.id,
                                begin: form.begin,
                                end: form.end,
                                description: form.description,
                                tags: form.tags,
                                fixedRate: form.fixedRate,
                                hourlyRate: form.hourlyRate,
                                user: form.user,
                                exported: form.exported,
                                billable: form.billable
                            )
                        } else {
                            throw NetworkService.APIError.validationError("Keine gültige Activity für dieses Projekt verfügbar")
                        }
                    }
                }
            } catch is TimeoutError {
                // Fallback: Verwende die ursprüngliche Activity und lasse den Server entscheiden
            } catch {
                // Fallback: Verwende die ursprüngliche Activity und lasse den Server entscheiden
            }
            
            let timesheet = try await networkService.createTimesheet(form: validatedForm, user: user)
            
            // Get temp hash for matching
            let tempHash = item.tempIdHash ?? -(abs(tempId.hashValue) % 1_000_000)
            
            // Update all pending UPDATE/DELETE operations that reference this temp ID
            pendingOpsManager.updateOperationsWithTempId(tempHash, newId: timesheet.id)
            
            // Remove temporary timesheet from cache (negative ID) and replace with real one
            await networkService.replaceTemporaryTimesheetInCache(tempId: tempHash, realTimesheet: timesheet, user: user)
            
            // Store temp ID mapping
            pendingOpsManager.markAsCompleted(item, serverId: timesheet.id)
            
        case .updateTimesheet(let id, let form):
            // Check if this is a negative (temp) ID
            if id < 0 {
                // Check if there's a CREATE operation for this temp ID that hasn't been synced yet
                let hasCreateOp = pendingOpsManager.pendingOperations.contains(where: { otherItem in
                    if case .createTimesheet = otherItem.operation, otherItem.tempIdHash == id {
                        // Only consider it if it hasn't been completed yet
                        return otherItem.status != .completed
                    }
                    return false
                })
                
                if hasCreateOp {
                    // CREATE will be synced first, then this UPDATE will be updated
                    throw NSError(domain: "OfflineSync", code: 404, userInfo: [NSLocalizedDescriptionKey: "Negative ID - CREATE Operation noch nicht synchronisiert"])
                } else {
                    // Check if the operation was already updated in the queue
                    // (this can happen if updateOperationsWithTempId was called earlier in this sync session)
                    if let currentItem = pendingOpsManager.pendingOperations.first(where: { $0.id == item.id }),
                       case .updateTimesheet(let currentId, _) = currentItem.operation,
                       currentId != id && currentId > 0 {
                        // The operation was already updated - use the new ID
                        try await ensureTagsExist(form: form, user: user)
                        _ = try await networkService.updateTimesheet(id: currentId, form: form, user: user)
                        pendingOpsManager.markAsCompleted(currentItem)
                        return
                    }
                    
                    // CREATE was already synced in a previous session - this UPDATE is orphaned
                    pendingOpsManager.markAsCompleted(item)
                    return
                }
            }
            
            // Stelle sicher, dass alle Tags existieren, bevor wir das Timesheet aktualisieren
            try await ensureTagsExist(form: form, user: user)
            
            _ = try await networkService.updateTimesheet(id: id, form: form, user: user)
            pendingOpsManager.markAsCompleted(item)
            
        case .deleteTimesheet(let id):
            // Check if this is a negative (temp) ID
            if id < 0 {
                // Check if there's a CREATE operation for this temp ID
                let hasCreateOp = pendingOpsManager.pendingOperations.contains(where: { item in
                    if case .createTimesheet = item.operation, item.tempIdHash == id {
                        return true
                    }
                    return false
                })
                
                if hasCreateOp {
                    // CREATE will be synced first, then this DELETE will be updated
                    throw NSError(domain: "OfflineSync", code: 404, userInfo: [NSLocalizedDescriptionKey: "Negative ID - CREATE Operation noch nicht synchronisiert"])
                } else {
                    // CREATE was already synced in a previous session - this DELETE is orphaned
                    pendingOpsManager.markAsCompleted(item)
                    return
                }
            }
            
            try await networkService.deleteTimesheet(id: id, user: user)
            pendingOpsManager.markAsCompleted(item)
        }
    }
    
    // MARK: - Helper Functions
    
    /// Execute an async operation with a timeout
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                return try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            
            guard let result = try await group.next() else {
                throw TimeoutError()
            }
            
            group.cancelAll()
            return result
        }
    }
    
    private struct TimeoutError: Error {}
    
    // MARK: - Tag Management
    
    /// Stellt sicher, dass alle Tags aus dem Form existieren, bevor ein Timesheet erstellt/aktualisiert wird
    private func ensureTagsExist(form: TimesheetEditForm, user: User) async throws {
        guard let tagsString = form.tags, !tagsString.isEmpty else {
            return // Keine Tags vorhanden
        }
        
        let tags = TagUtils.tags(from: tagsString)
        guard !tags.isEmpty else {
            return // Keine gültigen Tags
        }
        
        for tagName in tags {
            // Prüfe, ob Tag bereits existiert
            do {
                if let _ = try await networkService.findTagByName(tagName, user: user) {
                    continue
                }
            } catch {
                // Bei Fehler beim Prüfen: versuche trotzdem zu erstellen
            }
            
            // Tag existiert nicht - erstelle ihn
            do {
                _ = try await networkService.createTag(name: tagName, user: user)
            } catch {
                // Fehler beim Erstellen eines Tags ist nicht kritisch - das Timesheet kann trotzdem gespeichert werden
                // Die API wird den nicht-existierenden Tag einfach ignorieren
            }
        }
    }
    
    // MARK: - Manual Sync Trigger
    
    func triggerManualSync(for user: User) async {
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


