//
//  WatchTimerViewModel.swift
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
import WatchKit

@MainActor
class WatchTimerViewModel: ObservableObject {
    @Published var currentTimer: ActiveTimer?
    @Published var isStarting = false
    @Published var isStopping = false
    @Published var errorMessage: String?
    
    private let watchConnectivity = WatchConnectivityService.shared
    
    init() {
        // Observe timer status updates
        watchConnectivity.onTimerStatusUpdate = { [weak self] timer in
            self?.currentTimer = timer
        }
        
        // Observe errors
        watchConnectivity.onError = { [weak self] error in
            self?.errorMessage = error
        }
        
        // Get initial timer status
        currentTimer = watchConnectivity.currentTimer
    }
    
    var isTimerRunning: Bool {
        return currentTimer != nil
    }
    
    func startTimer(
        projectId: Int,
        projectName: String,
        activityId: Int,
        activityName: String,
        customerId: Int,
        customerName: String,
        description: String?
    ) {
        isStarting = true
        errorMessage = nil
        
        // Haptic feedback
        WKInterfaceDevice.current().play(.start)
        
        watchConnectivity.startTimer(
            projectId: projectId,
            projectName: projectName,
            activityId: activityId,
            activityName: activityName,
            customerId: customerId,
            customerName: customerName,
            description: description
        )
        
        // Reset starting state after a delay
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            isStarting = false
        }
    }
    
    func stopTimer(description: String? = nil) {
        guard currentTimer != nil else { return }
        
        isStopping = true
        errorMessage = nil
        
        // Haptic feedback
        WKInterfaceDevice.current().play(.stop)
        
        watchConnectivity.stopTimer(description: description)
        
        // Reset stopping state after a delay
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            isStopping = false
        }
    }
}

