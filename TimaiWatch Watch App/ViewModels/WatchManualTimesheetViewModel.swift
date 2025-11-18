//
//  WatchManualTimesheetViewModel.swift
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
import Combine

@MainActor
class WatchManualTimesheetViewModel: ObservableObject {
    @Published var selectedCustomer: WatchProjectSelectionViewModel.CustomerItem?
    @Published var selectedProject: WatchProjectSelectionViewModel.ProjectItem?
    @Published var selectedActivity: WatchProjectSelectionViewModel.ActivityItem?
    @Published var startDate = Date()
    @Published var endDate = Date()
    @Published var description = ""
    @Published var isCreating = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let watchConnectivity = WatchConnectivityService.shared
    
    init() {
        watchConnectivity.addErrorObserver { [weak self] error in
            self?.errorMessage = error
        }
    }
    
    var canCreate: Bool {
        selectedProject != nil && selectedActivity != nil && endDate > startDate
    }
    
    func createTimesheet() {
        guard let project = selectedProject,
              let activity = selectedActivity else {
            errorMessage = "watch.manual.error.missingData".localized()
            return
        }
        
        guard endDate > startDate else {
            errorMessage = "watch.manual.error.invalidDateRange".localized()
            return
        }
        
        isCreating = true
        errorMessage = nil
        
        watchConnectivity.createTimesheet(
            projectId: project.id,
            activityId: activity.id,
            startDate: startDate,
            endDate: endDate,
            description: description.isEmpty ? nil : description
        )
        
        // Reset after a delay to show success
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            await MainActor.run {
                isCreating = false
                successMessage = "watch.manual.success".localized()
            }
        }
    }
    
    func reset() {
        selectedCustomer = nil
        selectedProject = nil
        selectedActivity = nil
        startDate = Date()
        endDate = Date()
        description = ""
        errorMessage = nil
        successMessage = nil
    }
}

