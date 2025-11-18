//
//  TimesheetDetailView.swift
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

struct TimesheetDetailView: View {
    @Environment(\.dismiss) var dismiss
    let timesheet: WatchTimesheetListViewModel.TimesheetItem
    
    var body: some View {
        NavigationStack {
            List {
                Section("watch.detail.project".localized()) {
                    Text(timesheet.projectName)
                }
                
                Section("watch.detail.activity".localized()) {
                    Text(timesheet.activityName)
                }
                
                Section("watch.detail.customer".localized()) {
                    Text(timesheet.customerName)
                }
                
                if let description = timesheet.description, !description.isEmpty {
                    Section("watch.detail.description".localized()) {
                        Text(description)
                    }
                }
                
                if !timesheet.tags.isEmpty {
                    Section("watch.detail.tags".localized()) {
                        ForEach(timesheet.tags, id: \.self) { tag in
                            Text(tag)
                        }
                    }
                }
                
                Section("watch.detail.time".localized()) {
                    HStack {
                        Text("watch.detail.start".localized())
                        Spacer()
                        Text(formatDate(timesheet.startDateTime))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("watch.detail.end".localized())
                        Spacer()
                        Text(formatDate(timesheet.endDateTime))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("watch.detail.duration".localized())
                        Spacer()
                        Text(timesheet.formattedDuration)
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }
                }
            }
            .navigationTitle("watch.detail.title".localized())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("watch.detail.close".localized()) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

