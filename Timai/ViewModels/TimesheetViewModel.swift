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

@MainActor
class TimesheetViewModel: ObservableObject {
    @Published var activities: [Activity] = []
    @Published var sections: [(date: Date, activities: [Activity])] = []
    @Published var stats: TimesheetStats?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkService = NetworkService.shared
    private var currentUser: User?
    
    struct TimesheetStats {
        let today: String
        let thisWeek: String
        let thisMonth: String
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
                activities = fetchedActivities
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
        guard let user = currentUser else { return }
        
        do {
            try await networkService.deleteTimesheet(id: id, user: user)
            await loadTimesheets()
        } catch {
            print("❌ [TimesheetViewModel] Fehler beim Löschen: \(error)")
            errorMessage = "Fehler beim Löschen des Eintrags"
        }
    }
    
    private func calculateSections() {
        var lastDate: Date?
        var tempSections: [(date: Date, activities: [Activity])] = []
        var currentSectionActivities: [Activity] = []
        
        for activity in activities {
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

