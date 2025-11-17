//
//  TimesheetViewModel.swift
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

@MainActor
class TimesheetViewModel: ObservableObject {
    @Published var activities: [Activity] = []
    @Published var sections: [(date: Date, activities: [Activity])] = []
    @Published var stats: TimesheetStats?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    @Published var searchFilters: SearchFilters = SearchFilters()
    
    private let networkService = NetworkService.shared
    private let pendingOpsManager = PendingOperationsManager.shared
    private var currentUser: User?
    private var cancellables = Set<AnyCancellable>()
    
    // Track locally deleted items (not yet synced)
    private var locallyDeletedIds: Set<Int> = []
    
    struct TimesheetStats {
        let today: String
        let thisWeek: String
        let thisMonth: String
    }
    
    init() {
        setupSyncNotifications()
    }
    
    private func setupSyncNotifications() {
        // Listen for sync completion
        NotificationCenter.default.publisher(for: .syncCompleted)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.onSyncCompleted()
                }
            }
            .store(in: &cancellables)
        
        // Listen for instance changes
        NotificationCenter.default.publisher(for: .instanceDidChange)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.onInstanceChanged()
                }
            }
            .store(in: &cancellables)
    }
    
    private func onSyncCompleted() {
        print("✅ [TimesheetViewModel] Sync abgeschlossen - lade Timesheets neu")
        clearLocallyDeleted()
        Task {
            await loadTimesheets()
        }
    }
    
    private func onInstanceChanged() {
        print("🔄 [TimesheetViewModel] Instanz gewechselt - lade Timesheets neu")
        clearLocallyDeleted()
        Task {
            await loadTimesheets()
        }
    }
    
    func setUser(_ user: User) {
        self.currentUser = user
    }
    
    func loadTimesheets() async {
        guard let user = currentUser else {
            print("❌ [TimesheetViewModel] Kein User gesetzt")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedActivities = try await networkService.getTimesheetFor(user)
            
            if fetchedActivities.isEmpty {
                errorMessage = "error.message.noTimesheetRecords".localized()
                activities = []
                sections = []
                stats = nil
            } else {
                // Filter out locally deleted items
                activities = fetchedActivities.filter { !locallyDeletedIds.contains($0.recordId) }
                // Sections werden automatisch neu berechnet wenn filteredActivities sich ändert
                calculateSections()
                calculateStats()
            }
        } catch {
            print("❌ [TimesheetViewModel] Fehler beim Laden: \(error)")
            errorMessage = "error.message.couldntReceiveRecords".localized()
        }
        
        isLoading = false
    }
    
    func deleteTimesheet(id: Int) async {
        guard let user = currentUser else { 
            print("❌ [TimesheetViewModel] Kein User - Delete abgebrochen")
            return 
        }
        
        print("🗑️ [TimesheetViewModel] Lösche Timesheet ID: \(id)")
        
        // Optimistically remove from local list
        locallyDeletedIds.insert(id)
        activities.removeAll { $0.recordId == id }
        // Sections werden automatisch neu berechnet wenn filteredActivities sich ändert
        calculateSections()
        calculateStats()
        
        print("✅ [TimesheetViewModel] Eintrag lokal entfernt - \(activities.count) Einträge übrig")
        
        do {
            try await networkService.deleteTimesheet(id: id, user: user)
            
            print("✅ [TimesheetViewModel] Delete abgeschlossen")
            
            // Check if operation was added to pending queue
            if pendingOpsManager.hasPendingOperations {
                print("⚠️ [TimesheetViewModel] Operation in Pending Queue - warte auf Sync")
            } else {
                print("✅ [TimesheetViewModel] Delete erfolgreich - lade Liste neu")
                // If online and successful, reload to confirm
                await loadTimesheets()
                
                // Clear from locally deleted after successful sync
                locallyDeletedIds.remove(id)
            }
        } catch {
            print("❌ [TimesheetViewModel] Fehler beim Löschen: \(error)")
            print("🔍 [TimesheetViewModel] Error Type: \(type(of: error))")
            
            // Always keep in locally deleted and pending ops - will be synced when online
            print("📥 [TimesheetViewModel] Lösch-Operation vorgemerkt für ID: \(id)")
            // Don't restore the item - keep it deleted locally
        }
    }
    
    /// Check if an activity is pending deletion
    func isPendingDeletion(_ activityId: Int) -> Bool {
        return locallyDeletedIds.contains(activityId)
    }
    
    /// Check if an activity has pending operations (create, update, or delete)
    func isPendingSync(_ activityId: Int) -> Bool {
        // Use the new helper method in PendingOperationsManager
        let hasPending = pendingOpsManager.hasPendingOperationForId(activityId)
        
        if hasPending {
            print("🟡 [TimesheetViewModel] Activity \(activityId) IST pending sync")
        }
        
        return hasPending
    }
    
    /// Clear locally deleted items after successful sync
    func clearLocallyDeleted() {
        locallyDeletedIds.removeAll()
    }
    
    /// Gefilterte Aktivitäten basierend auf Suchtext und Filtern
    var filteredActivities: [Activity] {
        var filtered = activities
        
        // Textsuche
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            filtered = filtered.filter { activity in
                activity.customerName.lowercased().contains(searchLower) ||
                activity.projectName.lowercased().contains(searchLower) ||
                activity.task.lowercased().contains(searchLower) ||
                (activity.description?.lowercased().contains(searchLower) ?? false) ||
                (activity.tags?.contains { $0.lowercased().contains(searchLower) } ?? false)
            }
        }
        
        // Datumsfilter
        if let dateFrom = searchFilters.dateFrom {
            filtered = filtered.filter { activity in
                activity.startDateTime >= dateFrom
            }
        }
        
        if let dateTo = searchFilters.dateTo {
            // Setze dateTo auf Ende des Tages (23:59:59)
            let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: dateTo) ?? dateTo
            filtered = filtered.filter { activity in
                activity.startDateTime <= endOfDay
            }
        }
        
        // Kundenfilter
        if let customerId = searchFilters.selectedCustomerId {
            filtered = filtered.filter { activity in
                activity.customerId == customerId
            }
        }
        
        // Projektfilter
        if let projectId = searchFilters.selectedProjectId {
            filtered = filtered.filter { activity in
                activity.projectId == projectId
            }
        }
        
        // Tag-Filter (mindestens ein Tag muss übereinstimmen)
        if !searchFilters.selectedTags.isEmpty {
            let selectedTagsLower = Set(searchFilters.selectedTags.map { $0.lowercased() })
            filtered = filtered.filter { activity in
                guard let tags = activity.tags else { return false }
                return tags.contains { tag in
                    selectedTagsLower.contains(tag.lowercased())
                }
            }
        }
        
        return filtered
    }
    
    func calculateSections() {
        var lastDate: Date?
        var tempSections: [(date: Date, activities: [Activity])] = []
        var currentSectionActivities: [Activity] = []
        
        // Verwende gefilterte Aktivitäten für Sections
        let activitiesToUse = filteredActivities
        
        for activity in activitiesToUse {
            let activityDate = Calendar.current.startOfDay(for: activity.startDateTime)
            
            if let last = lastDate {
                let comparison = Calendar.current.compare(last, to: activityDate, toGranularity: .day)
                if comparison != .orderedSame {
                    // Neue Section
                    if !currentSectionActivities.isEmpty {
                        tempSections.append((date: last, activities: currentSectionActivities))
                    }
                    currentSectionActivities = [activity]
                    lastDate = activityDate
                } else {
                    currentSectionActivities.append(activity)
                }
            } else {
                // Erste Activity
                lastDate = activityDate
                currentSectionActivities = [activity]
            }
        }
        
        // Letzte Section hinzufügen
        if let last = lastDate, !currentSectionActivities.isEmpty {
            tempSections.append((date: last, activities: currentSectionActivities))
        }
        
        sections = tempSections
    }
    
    private func calculateStats() {
        var secondsToday = 0
        var secondsThisWeek = 0
        var secondsThisMonth = 0
        
        for activity in activities {
            let secondsDifferences = Calendar.current.dateComponents([.second],
                                                                     from: activity.startDateTime,
                                                                     to: activity.endDateTime).second ?? 0
            
            let day = Calendar.current.compare(activity.startDateTime, to: Date(), toGranularity: .day)
            if day == .orderedSame {
                secondsToday += secondsDifferences
            }
            
            let week = Calendar.current.compare(activity.startDateTime, to: Date(), toGranularity: .weekOfYear)
            if week == .orderedSame {
                secondsThisWeek += secondsDifferences
            }
            
            let month = Calendar.current.compare(activity.startDateTime, to: Date(), toGranularity: .month)
            if month == .orderedSame {
                secondsThisMonth += secondsDifferences
            }
        }
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.zeroFormattingBehavior = .pad
        
        stats = TimesheetStats(
            today: formatter.string(from: TimeInterval(secondsToday)) ?? "00:00",
            thisWeek: formatter.string(from: TimeInterval(secondsThisWeek)) ?? "00:00",
            thisMonth: formatter.string(from: TimeInterval(secondsThisMonth)) ?? "00:00"
        )
    }
}

