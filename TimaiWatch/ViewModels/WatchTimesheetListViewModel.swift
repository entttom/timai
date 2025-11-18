//
//  WatchTimesheetListViewModel.swift
//  TimaiWatch
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
class WatchTimesheetListViewModel: ObservableObject {
    @Published var timesheets: [TimesheetItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let watchConnectivity = WatchConnectivityService.shared
    
    // Compact data model for Watch
    struct TimesheetItem: Identifiable {
        let id: Int
        let projectName: String
        let activityName: String
        let customerName: String
        let startDateTime: Date
        let endDateTime: Date
        let description: String?
        let tags: [String]
        
        var duration: TimeInterval {
            return endDateTime.timeIntervalSince(startDateTime)
        }
        
        var formattedDuration: String {
            let hours = Int(duration) / 3600
            let minutes = (Int(duration) % 3600) / 60
            return String(format: "%d:%02d", hours, minutes)
        }
        
        var formattedDate: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: startDateTime)
        }
    }
    
    init() {
        // Observe timesheet list updates
        watchConnectivity.onTimesheetListUpdate = { [weak self] activities in
            Task { @MainActor in
                self?.handleTimesheetListUpdate(activities)
            }
        }
        
        // Observe errors
        watchConnectivity.onError = { [weak self] error in
            self?.errorMessage = error
        }
    }
    
    func loadTimesheets() {
        isLoading = true
        errorMessage = nil
        watchConnectivity.requestData(.timesheets)
    }
    
    private func handleTimesheetListUpdate(_ activities: [[String: Any]]) {
        timesheets = activities.compactMap { activity in
            guard let id = activity["id"] as? Int,
                  let projectName = activity["projectName"] as? String,
                  let activityName = activity["activityName"] as? String,
                  let customerName = activity["customerName"] as? String,
                  let startTimestamp = activity["startDateTime"] as? TimeInterval,
                  let endTimestamp = activity["endDateTime"] as? TimeInterval else {
                return nil
            }
            
            let description = activity["description"] as? String
            let tags = activity["tags"] as? [String] ?? []
            
            return TimesheetItem(
                id: id,
                projectName: projectName,
                activityName: activityName,
                customerName: customerName,
                startDateTime: Date(timeIntervalSince1970: startTimestamp),
                endDateTime: Date(timeIntervalSince1970: endTimestamp),
                description: description,
                tags: tags
            )
        }
        isLoading = false
    }
}

