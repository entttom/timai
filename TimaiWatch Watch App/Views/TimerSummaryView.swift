//
//  TimerSummaryView.swift
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

struct TimerSummaryView: View {
    let customer: WatchProjectSelectionViewModel.CustomerItem
    let project: WatchProjectSelectionViewModel.ProjectItem
    let activity: WatchProjectSelectionViewModel.ActivityItem
    @Binding var isPresented: Bool
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var timerViewModel: WatchTimerViewModel
    @State private var descriptionText = ""
    
    var body: some View {
        List {
            Section("watch.summary.customer".localized()) {
                Text(customer.name)
            }
            
            Section("watch.summary.project".localized()) {
                Text(project.name)
            }
            
            Section("watch.summary.activity".localized()) {
                Text(activity.name)
            }
            
            Section("watch.selection.description".localized()) {
                TextField("watch.selection.description.placeholder".localized(), text: $descriptionText)
            }
            
            Section {
                Button {
                    startTimer()
                } label: {
                    HStack {
                        Spacer()
                        Text("watch.timer.start".localized())
                            .font(.headline)
                        Spacer()
                    }
                }
                .disabled(timerViewModel.isStarting)
            }
        }
        .navigationTitle("watch.summary.title".localized())
    }
    
    private func startTimer() {
        timerViewModel.startTimer(
            projectId: project.id,
            projectName: project.name,
            activityId: activity.id,
            activityName: activity.name,
            customerId: customer.id,
            customerName: customer.name,
            description: descriptionText.isEmpty ? nil : descriptionText
        )
        
        // Navigation zurücksetzen
        navigationPath = NavigationPath()
        // Schließe das gesamte Sheet und alle verschachtelten Views
        isPresented = false
    }
}

