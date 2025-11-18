//
//  TimaiWatchApp.swift
//  TimaiWatch
//
//  Copyright (c) 2025 Dr. Thomas Entner.
//  All rights reserved.
//
//  Licensed under the Business Source License 1.1.
//  Usage is free for non-commercial and personal use.
//  Commercial use requires a commercial license.
//
import SwiftUI

@main
struct TimaiWatchApp: App {
    @StateObject private var timerViewModel = WatchTimerViewModel()
    @StateObject private var projectSelectionViewModel = WatchProjectSelectionViewModel()
    @StateObject private var timesheetListViewModel = WatchTimesheetListViewModel()
    
    init() {
        // Initialize WatchConnectivityService
        WatchConnectivityService.shared.setup()
    }
    
    var body: some Scene {
        WindowGroup {
            TimerView()
                .environmentObject(timerViewModel)
                .environmentObject(projectSelectionViewModel)
                .environmentObject(timesheetListViewModel)
        }
    }
}

