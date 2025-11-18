//
//  WatchInstanceSelectionViewModel.swift
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
class WatchInstanceSelectionViewModel: ObservableObject {
    @Published var instances: [InstanceItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentInstanceId: String?
    
    private let watchConnectivity = WatchConnectivityService.shared
    
    // Compact data model for Watch
    struct InstanceItem: Identifiable, Hashable {
        let id: String
        let name: String
        let apiEndpoint: String
        let isActive: Bool
    }
    
    init() {
        // Observe data responses (use addDataResponseObserver to support multiple ViewModels)
        watchConnectivity.addDataResponseObserver { [weak self] type, data in
            Task { @MainActor in
                if type == .instances {
                    self?.handleInstancesResponse(data)
                }
            }
        }
        
        // Observe errors
        watchConnectivity.addErrorObserver { [weak self] error in
            self?.errorMessage = error
        }
    }
    
    func loadInstances() {
        isLoading = true
        errorMessage = nil
        watchConnectivity.requestData(.instances)
    }
    
    func switchToInstance(_ instance: InstanceItem) {
        watchConnectivity.switchInstance(instanceId: instance.id)
        currentInstanceId = instance.id
    }
    
    private func handleInstancesResponse(_ data: [[String: Any]]) {
        instances = data.compactMap { item in
            guard let id = item["id"] as? String,
                  let name = item["name"] as? String,
                  let apiEndpoint = item["apiEndpoint"] as? String,
                  let isActive = item["isActive"] as? Bool else {
                return nil
            }
            return InstanceItem(id: id, name: name, apiEndpoint: apiEndpoint, isActive: isActive)
        }
        
        // Set current instance
        if let activeInstance = instances.first(where: { $0.isActive }) {
            currentInstanceId = activeInstance.id
        } else if let firstInstance = instances.first {
            currentInstanceId = firstInstance.id
        }
        
        isLoading = false
    }
    
    var hasMultipleInstances: Bool {
        return instances.count > 1
    }
}

