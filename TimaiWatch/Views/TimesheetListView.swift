//
//  TimesheetListView.swift
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

struct TimesheetListView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var timesheetListViewModel: WatchTimesheetListViewModel
    @State private var selectedTimesheet: WatchTimesheetListViewModel.TimesheetItem?
    
    var body: some View {
        NavigationStack {
            List {
                if timesheetListViewModel.isLoading {
                    ProgressView()
                } else if timesheetListViewModel.timesheets.isEmpty {
                    Text("watch.timesheets.empty".localized())
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(timesheetListViewModel.timesheets) { timesheet in
                        Button {
                            selectedTimesheet = timesheet
                        } label: {
                            TimesheetRowView(timesheet: timesheet)
                        }
                    }
                }
            }
            .navigationTitle("watch.timesheets.title".localized())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("watch.timesheets.close".localized()) {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedTimesheet) { timesheet in
                TimesheetDetailView(timesheet: timesheet)
            }
            .onAppear {
                timesheetListViewModel.loadTimesheets()
            }
        }
    }
}

struct TimesheetRowView: View {
    let timesheet: WatchTimesheetListViewModel.TimesheetItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(timesheet.projectName)
                .font(.headline)
                .lineLimit(1)
            
            Text(timesheet.activityName)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            HStack {
                Text(timesheet.formattedDuration)
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text(timesheet.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

