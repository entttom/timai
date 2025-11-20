//
//  TimerManager.swift
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
import SwiftUI
import Combine

/// Manages active timer state and persistence
@MainActor
class TimerManager: ObservableObject {
    static let shared = TimerManager()
    
    @Published var activeTimer: ActiveTimer?
    
    private let userDefaultsKey = "activeTimer"
    private let networkService = NetworkService.shared
    private var liveActivityManager: LiveActivityManager?
    #if os(iOS)
    private var watchConnectivityService: WatchConnectivityService?
    #endif
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadTimerState()
        setupTimerObservers()
    }
    
    /// Set the LiveActivityManager (avoid circular dependency)
    func setLiveActivityManager(_ manager: LiveActivityManager) {
        self.liveActivityManager = manager
    }
    
    /// Set the WatchConnectivityService (avoid circular dependency)
    #if os(iOS)
    func setWatchConnectivityService(_ service: WatchConnectivityService) {
        self.watchConnectivityService = service
    }
    #endif
    
    /// Setup observers for timer changes
    private func setupTimerObservers() {
        // Observe timer changes and send to Watch
        $activeTimer
            .sink { [weak self] timer in
                #if os(iOS)
                if let service = self?.watchConnectivityService {
                    service.sendTimerStatus(timer)
                }
                #endif
            }
            .store(in: &cancellables)
        
        // Observe timer start/stop notifications
        NotificationCenter.default.publisher(for: .timerDidStart)
            .sink { [weak self] notification in
                if let timer = notification.object as? ActiveTimer {
                    #if os(iOS)
                    if let service = self?.watchConnectivityService {
                        service.sendTimerStatus(timer)
                    }
                    #endif
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .timerDidStop)
            .sink { [weak self] _ in
                #if os(iOS)
                if let service = self?.watchConnectivityService {
                    service.sendTimerStatus(nil)
                }
                #endif
            }
            .store(in: &cancellables)
    }
    
    /// Check if a timer is currently running
    var isTimerRunning: Bool {
        return activeTimer != nil
    }
    
    /// Start a new timer
    func startTimer(
        projectId: Int,
        projectName: String,
        activityId: Int,
        activityName: String,
        customerId: Int,
        customerName: String,
        description: String? = nil,
        user: User
    ) async throws {
        // Stop any existing timer first
        if let existing = activeTimer {
            print("⚠️ [TimerManager] Timer läuft bereits - stoppe zuerst den alten Timer")
            try await stopTimer(user: user)
        }
        
        print("▶️ [TimerManager] Starte Timer für Projekt: \(projectName) - Activity: \(activityName)")
        
        // Create timer on Kimai server (without end date = running timer)
        let form = TimesheetEditForm(
            project: projectId,
            activity: activityId,
            begin: Date().ISO8601Format(),
            end: nil,  // No end = running timer
            description: description,
            tags: nil,
            fixedRate: nil,
            hourlyRate: nil,
            user: nil,
            exported: nil,
            billable: true
        )
        
        var timesheetId: Int?
        
        do {
            let timesheet = try await networkService.createTimesheet(form: form, user: user)
            timesheetId = timesheet.id
            print("✅ [TimerManager] Timer auf Server gestartet mit ID: \(timesheet.id)")
        } catch {
            print("⚠️ [TimerManager] Konnte Timer nicht auf Server starten: \(error)")
            print("📱 [TimerManager] Timer wird lokal gestartet und später synchronisiert")
            // Continue with local timer - will sync when online
        }
        
        // Create local timer state
        let timer = ActiveTimer(
            timesheetId: timesheetId,
            projectId: projectId,
            projectName: projectName,
            activityId: activityId,
            activityName: activityName,
            customerId: customerId,
            customerName: customerName,
            startDate: Date(),
            description: description
        )
        
        activeTimer = timer
        saveTimerState()
        
        // Start Live Activity
        print("🔔 [TimerManager] Rufe LiveActivityManager auf...")
        if let lam = liveActivityManager {
            print("✅ [TimerManager] LiveActivityManager gefunden - starte Activity")
            await lam.startTimerActivity(timer: timer)
        } else {
            print("❌ [TimerManager] LiveActivityManager ist NIL!")
        }
        
        // Post notification
        NotificationCenter.default.post(name: .timerDidStart, object: timer)
        
        // Send to Watch (already handled by observer, but send immediately)
        #if os(iOS)
        if let service = watchConnectivityService {
            service.sendTimerStatus(timer)
        }
        #endif
        
        print("✅ [TimerManager] Timer erfolgreich gestartet")
    }
    
    /// Stop the active timer
    func stopTimer(user: User, finalDescription: String? = nil) async throws {
        guard let timer = activeTimer else {
            print("⚠️ [TimerManager] Kein aktiver Timer zum Stoppen")
            return
        }
        
        print("⏹️ [TimerManager] Stoppe Timer für Projekt: \(timer.projectName)")
        
        let endDate = Date()
        
        // Stop timer on server
        if let timesheetId = timer.timesheetId {
            // Check if this is a negative (temp) ID from an offline timer
            if timesheetId < 0 {
                // Timer was created offline - try to update the pending CREATE operation instead of creating an UPDATE
                let pendingOpsManager = PendingOperationsManager.shared
                if let tempIdHash = pendingOpsManager.updatePendingTimerCreateOperation(
                    projectId: timer.projectId,
                    activityId: timer.activityId,
                    beginDate: timer.startDate,
                    endDate: endDate,
                    description: finalDescription ?? timer.description
                ) {
                    print("✅ [TimerManager] Pending CREATE Operation für Timer aktualisiert (end-Datum hinzugefügt)")
                    // Update cache with the new end date
                    await updateCacheForStoppedTimer(timesheetId: tempIdHash, endDate: endDate, user: user)
                    // No need to create an UPDATE operation - the CREATE operation now has the end date
                } else {
                    // CREATE operation not found - create UPDATE operation as fallback
                    let form = TimesheetEditForm(
                        project: timer.projectId,
                        activity: timer.activityId,
                        begin: timer.startDate.ISO8601Format(),
                        end: endDate.ISO8601Format(),
                        description: finalDescription ?? timer.description,
                        tags: nil,
                        fixedRate: nil,
                        hourlyRate: nil,
                        user: nil,
                        exported: nil,
                        billable: true
                    )
                    
                    do {
                        _ = try await networkService.updateTimesheet(id: timesheetId, form: form, user: user)
                        print("✅ [TimerManager] Timer auf Server gestoppt")
                    } catch {
                        print("⚠️ [TimerManager] Konnte Timer nicht auf Server stoppen: \(error)")
                        print("📥 [TimerManager] Timer-Stop wird später synchronisiert")
                        // Offline mode will queue this operation
                    }
                }
            } else {
                // Positive ID - timer exists on server, update it
                let form = TimesheetEditForm(
                    project: timer.projectId,
                    activity: timer.activityId,
                    begin: timer.startDate.ISO8601Format(),
                    end: endDate.ISO8601Format(),
                    description: finalDescription ?? timer.description,
                    tags: nil,
                    fixedRate: nil,
                    hourlyRate: nil,
                    user: nil,
                    exported: nil,
                    billable: true
                )
                
                do {
                    _ = try await networkService.updateTimesheet(id: timesheetId, form: form, user: user)
                    print("✅ [TimerManager] Timer auf Server gestoppt")
                } catch {
                    print("⚠️ [TimerManager] Konnte Timer nicht auf Server stoppen: \(error)")
                    print("📥 [TimerManager] Timer-Stop wird später synchronisiert")
                    // Offline mode will queue this operation
                }
            }
        } else {
            // Timer was only local - check if there's a pending CREATE operation for this timer
            let pendingOpsManager = PendingOperationsManager.shared
            if let tempIdHash = pendingOpsManager.updatePendingTimerCreateOperation(
                projectId: timer.projectId,
                activityId: timer.activityId,
                beginDate: timer.startDate,
                endDate: endDate,
                description: finalDescription ?? timer.description
            ) {
                print("✅ [TimerManager] Pending CREATE Operation für Timer aktualisiert (end-Datum hinzugefügt)")
                // Update cache with the new end date
                await updateCacheForStoppedTimer(timesheetId: tempIdHash, endDate: endDate, user: user)
                // No need to create a new timesheet - the existing CREATE operation will be synced with the end date
            } else {
                // No pending CREATE operation found - create new timesheet
                let form = TimesheetEditForm(
                    project: timer.projectId,
                    activity: timer.activityId,
                    begin: timer.startDate.ISO8601Format(),
                    end: endDate.ISO8601Format(),
                    description: finalDescription ?? timer.description,
                    tags: nil,
                    fixedRate: nil,
                    hourlyRate: nil,
                    user: nil,
                    exported: nil,
                    billable: true
                )
                
                do {
                    _ = try await networkService.createTimesheet(form: form, user: user)
                    print("✅ [TimerManager] Lokaler Timer als Timesheet auf Server erstellt")
                } catch {
                    print("⚠️ [TimerManager] Konnte Timesheet nicht erstellen: \(error)")
                    print("📥 [TimerManager] Timesheet wird später synchronisiert")
                }
            }
        }
        
        // Stop Live Activity
        await liveActivityManager?.stopTimerActivity()
        
        // Clear local state
        activeTimer = nil
        clearTimerState()
        
        // Post notification
        NotificationCenter.default.post(name: .timerDidStop, object: nil)
        
        // Send to Watch (already handled by observer, but send immediately)
        #if os(iOS)
        if let service = watchConnectivityService {
            service.sendTimerStatus(nil)
        }
        #endif
        
        print("✅ [TimerManager] Timer erfolgreich gestoppt")
    }
    
    /// Check for active timer on server and sync with local state
    func syncActiveTimerFromServer(user: User) async {
        print("🔍 [TimerManager] Prüfe auf aktive Timer auf dem Server...")
        
        do {
            // Fetch running timer from server (end = nil)
            guard let runningTimesheet = try await networkService.getActiveTimesheet(user: user) else {
                print("ℹ️ [TimerManager] Kein laufender Timer auf Server gefunden")
                // Clear local timer if exists but not on server
                if activeTimer != nil {
                    print("🧹 [TimerManager] Lösche veralteten lokalen Timer")
                    activeTimer = nil
                    clearTimerState()
                    await liveActivityManager?.stopTimerActivity()
                }
                return
            }
            
            print("✅ [TimerManager] Laufender Timer gefunden: \(runningTimesheet.projectName)")
            print("📊 [TimerManager] Timer-ID: \(runningTimesheet.id)")
            print("📊 [TimerManager] Start: \(runningTimesheet.begin)")
            
            // Create or update local timer with server data
            let timer = ActiveTimer(
                timesheetId: runningTimesheet.id,
                projectId: runningTimesheet.project.id,
                projectName: runningTimesheet.projectName,
                activityId: runningTimesheet.activity.id,
                activityName: runningTimesheet.task,
                customerId: runningTimesheet.project.customer.id,
                customerName: runningTimesheet.customerName,
                startDate: runningTimesheet.begin,  // ✅ Vom Server!
                description: runningTimesheet.description
            )
            
            activeTimer = timer
            saveTimerState()
            
            // Start Live Activity with correct start date
            print("🔔 [TimerManager] Starte Live Activity mit Server-Startzeit")
            await liveActivityManager?.startTimerActivity(timer: timer)
            
            // Send to Watch
            #if os(iOS)
            if let service = watchConnectivityService {
                service.sendTimerStatus(timer)
            }
            #endif
            
        } catch {
            print("❌ [TimerManager] Fehler beim Sync mit Server: \(error)")
            // Fallback to restoring from local state if available
            await restoreTimerFromLocalState()
        }
    }
    
    /// Restore timer state from local storage (fallback)
    private func restoreTimerFromLocalState() async {
        guard let timer = activeTimer else { 
            print("ℹ️ [TimerManager] Kein lokaler Timer-State vorhanden")
            return 
        }
        
        print("🔄 [TimerManager] Stelle Timer aus lokalem State wieder her: \(timer.projectName)")
        
        // Restart Live Activity with local data
        await liveActivityManager?.startTimerActivity(timer: timer)
    }
    
    // MARK: - Persistence
    
    private func saveTimerState() {
        guard let timer = activeTimer else { return }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(timer)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            print("💾 [TimerManager] Timer-State gespeichert")
        } catch {
            print("❌ [TimerManager] Fehler beim Speichern des Timer-State: \(error)")
        }
    }
    
    private func loadTimerState() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            print("ℹ️ [TimerManager] Kein gespeicherter Timer-State vorhanden")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let timer = try decoder.decode(ActiveTimer.self, from: data)
            activeTimer = timer
            print("✅ [TimerManager] Timer-State geladen: \(timer.projectName)")
        } catch {
            print("❌ [TimerManager] Fehler beim Laden des Timer-State: \(error)")
            clearTimerState()
        }
    }
    
    private func clearTimerState() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        print("🗑️ [TimerManager] Timer-State gelöscht")
    }
    
    /// Update cache for a stopped timer (when CREATE operation was updated)
    private func updateCacheForStoppedTimer(timesheetId: Int, endDate: Date, user: User) async {
        let cacheManager = CacheManager.shared
        
        do {
            var cachedTimesheets = (try? await cacheManager.load([Timesheet].self, for: user, cacheType: .timesheets)) ?? []
            
            // Find the timesheet with matching ID
            if let index = cachedTimesheets.firstIndex(where: { $0.id == timesheetId }) {
                let timesheet = cachedTimesheets[index]
                
                // Update the end date by creating a new Timesheet with updated values
                let updatedTimesheet = Timesheet(
                    id: timesheet.id,
                    begin: timesheet.begin,
                    end: endDate,
                    duration: Int(endDate.timeIntervalSince(timesheet.begin)),
                    user: timesheet.user,
                    activity: timesheet.activity,
                    project: timesheet.project,
                    description: timesheet.description,
                    rate: timesheet.rate,
                    internalRate: timesheet.internalRate,
                    fixedRate: timesheet.fixedRate,
                    hourlyRate: timesheet.hourlyRate,
                    exported: timesheet.exported,
                    billable: timesheet.billable,
                    tags: timesheet.tags
                )
                
                cachedTimesheets[index] = updatedTimesheet
                
                // Sortiere nach begin DESC (neueste zuerst)
                cachedTimesheets.sort { $0.begin > $1.begin }
                
                try await cacheManager.cache(cachedTimesheets, for: user, type: .timesheets)
                print("💾 [TimerManager] Cache aktualisiert - Timer \(timesheetId) mit end-Datum")
            }
        } catch {
            print("⚠️ [TimerManager] Konnte Cache nicht aktualisieren: \(error)")
        }
    }
}


// MARK: - Notification Names
extension Notification.Name {
    static let timerDidStart = Notification.Name("timerDidStart")
    static let timerDidStop = Notification.Name("timerDidStop")
}

