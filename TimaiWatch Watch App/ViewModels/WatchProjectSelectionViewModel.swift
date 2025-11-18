//
//  WatchProjectSelectionViewModel.swift
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
class WatchProjectSelectionViewModel: ObservableObject {
    @Published var customers: [CustomerItem] = []
    @Published var projects: [ProjectItem] = []
    @Published var activities: [ActivityItem] = []
    @Published var isLoadingCustomers = false
    @Published var isLoadingProjects = false
    @Published var isLoadingActivities = false
    @Published var errorMessage: String?
    
    private let watchConnectivity = WatchConnectivityService.shared
    
    // Compact data models for Watch
    struct CustomerItem: Identifiable, Hashable {
        let id: Int
        let name: String
    }
    
    struct ProjectItem: Identifiable, Hashable {
        let id: Int
        let name: String
        let customerId: Int
    }
    
    struct ActivityItem: Identifiable, Hashable {
        let id: Int
        let name: String
    }
    
    init() {
        // Observe data responses (use addDataResponseObserver to support multiple ViewModels)
        watchConnectivity.addDataResponseObserver { [weak self] type, data in
            Task { @MainActor in
                self?.handleDataResponse(type: type, data: data)
            }
        }
        
        // Observe errors
        watchConnectivity.addErrorObserver { [weak self] error in
            self?.errorMessage = error
        }
    }
    
    func loadCustomers() {
        isLoadingCustomers = true
        errorMessage = nil
        watchConnectivity.requestData(.customers)
    }
    
    func loadProjects(for customerId: Int) {
        isLoadingProjects = true
        errorMessage = nil
        projects = []
        watchConnectivity.requestData(.projects, customerId: customerId)
    }
    
    func loadActivities(for projectId: Int) {
        isLoadingActivities = true
        errorMessage = nil
        activities = []
        watchConnectivity.requestData(.activities, projectId: projectId)
    }
    
    private func handleDataResponse(type: WatchConnectivityService.DataRequestType, data: [[String: Any]]) {
        switch type {
        case .customers:
            customers = data.compactMap { item in
                guard let id = item["id"] as? Int,
                      let name = item["name"] as? String else {
                    return nil
                }
                return CustomerItem(id: id, name: name)
            }
            isLoadingCustomers = false
            
        case .projects:
            projects = data.compactMap { item in
                guard let id = item["id"] as? Int,
                      let name = item["name"] as? String,
                      let customerId = item["customerId"] as? Int else {
                    return nil
                }
                return ProjectItem(id: id, name: name, customerId: customerId)
            }
            isLoadingProjects = false
            
        case .activities:
            activities = data.compactMap { item in
                guard let id = item["id"] as? Int,
                      let name = item["name"] as? String else {
                    return nil
                }
                return ActivityItem(id: id, name: name)
            }
            isLoadingActivities = false
            
        case .timesheets:
            // Handled by WatchTimesheetListViewModel
            break
            
        case .instances:
            // Handled by WatchInstanceSelectionViewModel
            break
        }
    }
}

