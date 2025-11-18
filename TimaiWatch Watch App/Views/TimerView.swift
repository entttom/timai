//
//  TimerView.swift
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

struct TimerView: View {
    @EnvironmentObject var timerViewModel: WatchTimerViewModel
    @EnvironmentObject var projectSelectionViewModel: WatchProjectSelectionViewModel
    @EnvironmentObject var timesheetListViewModel: WatchTimesheetListViewModel
    @EnvironmentObject var instanceSelectionViewModel: WatchInstanceSelectionViewModel
    @State private var showProjectSelection = false
    @State private var showTimesheetList = false
    @State private var showManualTimesheet = false
    @State private var showInstanceSelection = false
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    if let timer = timerViewModel.currentTimer {
                        // Timer is running
                        TimerRunningView(timer: timer)
                    } else {
                        // No timer running
                        VStack(spacing: 12) {
                            Image(systemName: "timer")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            
                            Text("watch.timer.noTimer".localized())
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            
                            Button {
                                showProjectSelection = true
                            } label: {
                                Label("watch.timer.start".localized(), systemImage: "play.fill")
                                    .font(.headline)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    }
                    
                    // Navigation buttons
                    VStack(spacing: 8) {
                        Button {
                            showTimesheetList = true
                        } label: {
                            Label("watch.timer.timesheets".localized(), systemImage: "list.bullet")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        
                        Button {
                            showManualTimesheet = true
                        } label: {
                            Label("watch.timer.manualEntry".localized(), systemImage: "clock.badge.plus")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        
                        if instanceSelectionViewModel.hasMultipleInstances {
                            Button {
                                showInstanceSelection = true
                            } label: {
                                Label("watch.timer.instances".localized(), systemImage: "server.rack")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .navigationTitle("")
            .sheet(isPresented: $showProjectSelection) {
                NavigationStack(path: $navigationPath) {
                    CustomerSelectionView(isPresented: $showProjectSelection, navigationPath: $navigationPath)
                        .environmentObject(projectSelectionViewModel)
                }
            }
            .onChange(of: showProjectSelection) { _, isPresented in
                if !isPresented {
                    // Navigation zurücksetzen, wenn Sheet geschlossen wird
                    navigationPath = NavigationPath()
                }
            }
            .sheet(isPresented: $showTimesheetList) {
                TimesheetListView()
            }
            .sheet(isPresented: $showManualTimesheet) {
                ManualTimesheetView(isPresented: $showManualTimesheet)
            }
            .sheet(isPresented: $showInstanceSelection) {
                InstanceSelectionView()
            }
            .onAppear {
                // Check if multiple instances exist
                instanceSelectionViewModel.loadInstances()
            }
            .alert("watch.error.title".localized(), isPresented: .constant(timerViewModel.errorMessage != nil)) {
                Button("watch.error.ok".localized()) {
                    timerViewModel.errorMessage = nil
                }
            } message: {
                if let error = timerViewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }
}

struct TimerRunningView: View {
    let timer: ActiveTimer
    @EnvironmentObject var timerViewModel: WatchTimerViewModel
    @State private var elapsedTime: String = "00:00:00"
    @State private var timerTask: Task<Void, Never>?
    
    var body: some View {
        VStack(spacing: 12) {
            // Project and Activity info
            VStack(spacing: 4) {
                Text(timer.projectName)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(timer.activityName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            // Timer display
            Text(elapsedTime)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
            
            // Stop button
            Button {
                timerViewModel.stopTimer()
            } label: {
                Label("watch.timer.stop".localized(), systemImage: "stop.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(timerViewModel.isStopping)
        }
        .padding()
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func startTimer() {
        updateElapsedTime()
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                await MainActor.run {
                    updateElapsedTime()
                }
            }
        }
    }
    
    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }
    
    private func updateElapsedTime() {
        elapsedTime = timer.formattedElapsedTime
    }
}

// MARK: - Localization Extension
extension String {
    func localized() -> String {
        return NSLocalizedString(self, comment: "")
    }
}

