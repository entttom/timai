//
//  ManualTimesheetDateSelectionView.swift
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

struct ManualTimesheetDateSelectionView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var navigationPath: NavigationPath
    let customer: WatchProjectSelectionViewModel.CustomerItem
    let project: WatchProjectSelectionViewModel.ProjectItem
    let activity: WatchProjectSelectionViewModel.ActivityItem
    @Binding var isPresented: Bool
    @ObservedObject var manualTimesheetViewModel: WatchManualTimesheetViewModel
    
    var body: some View {
        List {
            Section("watch.manual.startDate".localized()) {
                DatePicker("watch.manual.date".localized(), selection: $startDate, displayedComponents: .date)
                DatePicker("watch.manual.time".localized(), selection: $startDate, displayedComponents: .hourAndMinute)
            }
            
            Section("watch.manual.endDate".localized()) {
                DatePicker("watch.manual.date".localized(), selection: $endDate, displayedComponents: .date)
                DatePicker("watch.manual.time".localized(), selection: $endDate, displayedComponents: .hourAndMinute)
            }
            
            if endDate <= startDate {
                Section {
                    Text("watch.manual.error.endBeforeStart".localized())
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            if endDate > startDate {
                Section {
                    NavigationLink {
                        ManualTimesheetSummaryView(
                            customer: customer,
                            project: project,
                            activity: activity,
                            startDate: startDate,
                            endDate: endDate,
                            isPresented: $isPresented,
                            navigationPath: $navigationPath
                        )
                        .environmentObject(manualTimesheetViewModel)
                    } label: {
                        HStack {
                            Spacer()
                            Text("watch.manual.continue".localized())
                                .font(.headline)
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle("watch.manual.dates".localized())
        .onAppear {
            manualTimesheetViewModel.selectedActivity = activity
        }
    }
}

