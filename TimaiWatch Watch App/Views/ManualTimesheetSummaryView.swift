//
//  ManualTimesheetSummaryView.swift
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

struct ManualTimesheetSummaryView: View {
    let customer: WatchProjectSelectionViewModel.CustomerItem
    let project: WatchProjectSelectionViewModel.ProjectItem
    let activity: WatchProjectSelectionViewModel.ActivityItem
    let startDate: Date
    let endDate: Date
    @Binding var isPresented: Bool
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var manualTimesheetViewModel: WatchManualTimesheetViewModel
    
    private var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
    
    private var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return String(format: "%02d:%02d", hours, minutes)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
    
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
            
            Section("watch.manual.startDate".localized()) {
                Text(dateFormatter.string(from: startDate))
            }
            
            Section("watch.manual.endDate".localized()) {
                Text(dateFormatter.string(from: endDate))
            }
            
            Section("watch.manual.duration".localized()) {
                Text(formattedDuration)
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
            }
            
            Section("watch.selection.description".localized()) {
                TextField("watch.selection.description.placeholder".localized(), text: $manualTimesheetViewModel.description)
            }
            
            Section {
                Button {
                    manualTimesheetViewModel.createTimesheet()
                    // Navigation zurücksetzen
                    navigationPath = NavigationPath()
                    // Sheet schließen
                    isPresented = false
                } label: {
                    HStack {
                        Spacer()
                        if manualTimesheetViewModel.isCreating {
                            ProgressView()
                        } else {
                            Text("watch.manual.save".localized())
                                .font(.headline)
                        }
                        Spacer()
                    }
                }
                .disabled(!manualTimesheetViewModel.canCreate || manualTimesheetViewModel.isCreating)
            }
        }
        .navigationTitle("watch.summary.title".localized())
    }
}

