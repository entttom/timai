//
//  TimesheetDetailView.swift
//  Timai
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
    let activity: Activity
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: TimesheetViewModel
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false
    
    var body: some View {
        List {
            // Customer & Project Section
            Section("timesheetDetail.section.project".localized()) {
                DetailRow(title: "timesheetDetail.field.customer".localized(), value: activity.customerName)
                DetailRow(title: "timesheetDetail.field.project".localized(), value: activity.projectName)
                DetailRow(title: "timesheetDetail.field.activity".localized(), value: activity.task)
            }
            
            // Time Section
            Section("timesheetDetail.section.time".localized()) {
                DetailRow(title: "timesheetDetail.field.start".localized(), value: formatDateTime(activity.startDateTime))
                DetailRow(title: "timesheetDetail.field.end".localized(), value: formatDateTime(activity.endDateTime))
                DetailRow(
                    title: "timesheetDetail.field.duration".localized(),
                    value: formatDuration(from: activity.startDateTime, to: activity.endDateTime)
                )
            }
            
            // Description Section
            if let description = activity.description, !description.isEmpty {
                Section("timesheetDetail.section.description".localized()) {
                    Text(description)
                        .font(.body)
                        .foregroundColor(.timaiTextBlack)
                }
            }
            
            // Tags Section
            if let tags = activity.tags, !tags.isEmpty {
                Section("timesheetDetail.section.tags".localized()) {
                    TagDisplayView(tags: tags)
                }
            }
            
            // Actions Section
            Section {
                Button(role: .destructive, action: { showingDeleteAlert = true }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("timesheetDetail.button.delete".localized())
                    }
                }
            }
        }
        .navigationTitle("timesheetDetail.navigationTitle".localized())
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("timesheetDetail.button.edit".localized()) {
                    showingEditSheet = true
                }
            }
            #else
            ToolbarItem(placement: .automatic) {
                Button("timesheetDetail.button.edit".localized()) {
                    showingEditSheet = true
                }
            }
            #endif
        }
        .alert("timesheetDetail.alert.delete.title".localized(), isPresented: $showingDeleteAlert) {
            Button("timesheetDetail.alert.delete.cancel".localized(), role: .cancel) {}
            Button("timesheetDetail.alert.delete.confirm".localized(), role: .destructive) {
                Task {
                    await viewModel.deleteTimesheet(id: activity.recordId)
                    dismiss()
                }
            }
        } message: {
            Text("timesheetDetail.alert.delete.message".localized())
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                TimesheetEditView(mode: .edit(activity: activity), onSaved: {
                    showingEditSheet = false
                    dismiss()
                })
                .environmentObject(viewModel)
            }
        }
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(from start: Date, to end: Date) -> String {
        let seconds = Calendar.current.dateComponents([.second], from: start, to: end).second ?? 0
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: TimeInterval(seconds)) ?? "00:00"
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.timaiSubheaderColor)
            Spacer()
            Text(value)
                .foregroundColor(.timaiTextBlack)
        }
    }
}

/// Anzeige von Tags in der Detailansicht (nur lesend, ohne Entfernen-Funktion)
struct TagDisplayView: View {
    let tags: [String]
    
    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                tagChip(tag)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func tagChip(_ tag: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "tag.fill")
                .font(.system(size: 10))
                .foregroundColor(.timaiHighlight.opacity(0.8))
            
            Text(tag)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.timaiTextBlack)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.timaiHighlight.opacity(0.12))
                .overlay(
                    Capsule()
                        .stroke(Color.timaiHighlight.opacity(0.25), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    NavigationStack {
        TimesheetDetailView(activity: Activity(
            recordId: 1,
            description: "Test Beschreibung",
            tags: ["Tag A", "Tag B"],
            customerName: "Test Kunde",
            customerId: 1,
            projectName: "Test Projekt",
            projectId: 1,
            task: "Entwicklung",
            activityId: 1,
            startDateTime: Date().addingTimeInterval(-3600),
            endDateTime: Date()
        ))
        .environmentObject(TimesheetViewModel())
    }
}

