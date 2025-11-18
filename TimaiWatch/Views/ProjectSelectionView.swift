//
//  ProjectSelectionView.swift
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

struct ProjectSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var timerViewModel: WatchTimerViewModel
    @EnvironmentObject var projectSelectionViewModel: WatchProjectSelectionViewModel
    
    @State private var selectedCustomerId: Int?
    @State private var selectedProjectId: Int?
    @State private var selectedActivityId: Int?
    @State private var descriptionText = ""
    @State private var showDescription = false
    
    var body: some View {
        NavigationStack {
            List {
                // Customer selection
                Section("watch.selection.customer".localized()) {
                    if projectSelectionViewModel.isLoadingCustomers {
                        ProgressView()
                    } else {
                        ForEach(projectSelectionViewModel.customers) { customer in
                            Button {
                                selectedCustomerId = customer.id
                                selectedProjectId = nil
                                selectedActivityId = nil
                                projectSelectionViewModel.loadProjects(for: customer.id)
                            } label: {
                                HStack {
                                    Text(customer.name)
                                    Spacer()
                                    if selectedCustomerId == customer.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Project selection
                if selectedCustomerId != nil {
                    Section("watch.selection.project".localized()) {
                        if projectSelectionViewModel.isLoadingProjects {
                            ProgressView()
                        } else {
                            ForEach(projectSelectionViewModel.projects.filter { $0.customerId == selectedCustomerId }) { project in
                                Button {
                                    selectedProjectId = project.id
                                    selectedActivityId = nil
                                    projectSelectionViewModel.loadActivities(for: project.id)
                                } label: {
                                    HStack {
                                        Text(project.name)
                                        Spacer()
                                        if selectedProjectId == project.id {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Activity selection
                if selectedProjectId != nil {
                    Section("watch.selection.activity".localized()) {
                        if projectSelectionViewModel.isLoadingActivities {
                            ProgressView()
                        } else {
                            ForEach(projectSelectionViewModel.activities) { activity in
                                Button {
                                    selectedActivityId = activity.id
                                    showDescription = true
                                } label: {
                                    HStack {
                                        Text(activity.name)
                                        Spacer()
                                        if selectedActivityId == activity.id {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Description input
                if selectedActivityId != nil && showDescription {
                    Section("watch.selection.description".localized()) {
                        TextField("watch.selection.description.placeholder".localized(), text: $descriptionText)
                    }
                    
                    // Start button
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
                        .disabled(!canStart || timerViewModel.isStarting)
                    }
                }
            }
            .navigationTitle("watch.selection.title".localized())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("watch.selection.cancel".localized()) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if projectSelectionViewModel.customers.isEmpty {
                    projectSelectionViewModel.loadCustomers()
                }
            }
        }
    }
    
    private var canStart: Bool {
        selectedProjectId != nil && selectedActivityId != nil
    }
    
    private func startTimer() {
        guard let projectId = selectedProjectId,
              let activityId = selectedActivityId,
              let project = projectSelectionViewModel.projects.first(where: { $0.id == projectId }),
              let customer = projectSelectionViewModel.customers.first(where: { $0.id == selectedCustomerId }) else {
            return
        }
        
        timerViewModel.startTimer(
            projectId: projectId,
            projectName: project.name,
            activityId: activityId,
            activityName: projectSelectionViewModel.activities.first(where: { $0.id == activityId })?.name ?? "",
            customerId: customer.id,
            customerName: customer.name,
            description: descriptionText.isEmpty ? nil : descriptionText
        )
        
        dismiss()
    }
}

