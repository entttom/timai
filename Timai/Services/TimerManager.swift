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
    
    private init() {
        loadTimerState()
    }
    
    /// Set the LiveActivityManager (avoid circular dependency)
    func setLiveActivityManager(_ manager: LiveActivityManager) {
        self.liveActivityManager = manager
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
            // Update existing timesheet with end date
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
        } else {
            // Create new timesheet (timer was only local)
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
        
        // Stop Live Activity
        await liveActivityManager?.stopTimerActivity()
        
        // Clear local state
        activeTimer = nil
        clearTimerState()
        
        // Post notification
        NotificationCenter.default.post(name: .timerDidStop, object: nil)
        
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
}


// MARK: - Notification Names
extension Notification.Name {
    static let timerDidStart = Notification.Name("timerDidStart")
    static let timerDidStop = Notification.Name("timerDidStop")
}

