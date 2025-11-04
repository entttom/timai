//
//  TimesheetView.swift
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

struct TimesheetView: View {
    @EnvironmentObject var viewModel: TimesheetViewModel
    @State private var showingAddSheet = false
    @State private var showToast = false
    
    var body: some View {
        ZStack {
            if viewModel.isLoading && viewModel.activities.isEmpty {
                LoadingView()
            } else if viewModel.activities.isEmpty && !viewModel.isLoading {
                EmptyStateView(
                    icon: "clock",
                    title: "Keine Einträge",
                    message: "error.message.noTimesheetRecords".localized(),
                    actionTitle: "Eintrag hinzufügen",
                    action: { showingAddSheet = true }
                )
            } else {
                List {
                    // Stats Section
                    if let stats = viewModel.stats {
                        Section {
                            TimesheetStatsView(stats: stats)
                        }
                    }
                    
                    // Activities by Date
                    ForEach(viewModel.sections, id: \.date) { section in
                        Section(header: Text(formatSectionDate(section.date))) {
                            ForEach(section.activities) { activity in
                                NavigationLink(destination: TimesheetDetailView(activity: activity)) {
                                    TimesheetRowView(activity: activity)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .background(Color.timaiGray)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("timesheet.navigationTitle".localized())
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .refreshable {
            await viewModel.loadTimesheets()
        }
        .sheet(isPresented: $showingAddSheet) {
            // Nach dem Schließen neu laden
            Task {
                await viewModel.loadTimesheets()
            }
        } content: {
            NavigationStack {
                TimesheetEditView(mode: .create, onSaved: {
                    showingAddSheet = false
                })
            }
        }
        .task {
            await viewModel.loadTimesheets()
        }
        .toast(
            isShowing: $showToast,
            message: viewModel.errorMessage ?? "",
            type: .warning
        )
        .onChange(of: viewModel.errorMessage) { newValue in
            if newValue != nil {
                showToast = true
            }
        }
    }
    
    private func formatSectionDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Timesheet Row
struct TimesheetRowView: View {
    let activity: Activity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Customer & Project
            Text(activity.customerName)
                .font(.headline)
                .foregroundColor(.timaiTextBlack)
            
            Text(activity.projectName)
                .font(.subheadline)
                .foregroundColor(.timaiSubheaderColor)
            
            // Task
            Text(activity.task)
                .font(.body)
                .foregroundColor(.timaiGrayTone3)
            
            // Time & Duration
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("\(formatTime(activity.startDateTime)) - \(formatTime(activity.endDateTime))")
                        .font(.caption)
                }
                .foregroundColor(.timaiGrayTone2)
                
                Spacer()
                
                Text(formatDuration(from: activity.startDateTime, to: activity.endDateTime))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.timaiHighlight)
            }
            
            // Description
            if let description = activity.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.timaiGrayTone2)
                    .lineLimit(2)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
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

// MARK: - Stats View
struct TimesheetStatsView: View {
    let stats: TimesheetViewModel.TimesheetStats
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                StatItemView(
                    title: "timesheet.stats.today".localized(),
                    value: stats.today
                )
                
                Divider()
                
                StatItemView(
                    title: "timesheet.stats.week".localized(),
                    value: stats.thisWeek
                )
                
                Divider()
                
                StatItemView(
                    title: "timesheet.stats.month".localized(),
                    value: stats.thisMonth
                )
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color.timaiCardBackground)
        .cornerRadius(10)
    }
}

struct StatItemView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.timaiHighlight)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.timaiSubheaderColor)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        TimesheetView()
            .environmentObject({
                let vm = TimesheetViewModel()
                return vm
            }())
    }
}

