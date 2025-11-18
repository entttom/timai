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
#if os(macOS)
import AppKit
#endif

struct TimesheetView: View {
    @EnvironmentObject var viewModel: TimesheetViewModel
    @StateObject private var instanceManager = InstanceManager.shared
    @StateObject private var timerManager = TimerManager.shared
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingAddSheet = false
    @State private var showingInstanceSwitcher = false
    @State private var showingTimerStartSheet = false
    @State private var showingTimerStopDialog = false
    @State private var showingSearchSheet = false
    @State private var showToast = false
    
    private var circleBackgroundColor: Color {
        #if os(iOS)
        return Color(.systemBackground)
        #else
        return Color(NSColor.windowBackgroundColor)
        #endif
    }
    
    private var toolbarLeadingPlacement: ToolbarItemPlacement {
        #if os(iOS)
        return .navigationBarLeading
        #else
        return .automatic
        #endif
    }
    
    private var toolbarTrailingPlacement: ToolbarItemPlacement {
        #if os(iOS)
        return .navigationBarTrailing
        #else
        return .automatic
        #endif
    }
    
    var body: some View {
        ZStack {
            // Timer Banner at the top
            VStack(spacing: 0) {
                if let timer = timerManager.activeTimer {
                    TimerBanner(timer: timer) {
                        showingTimerStopDialog = true
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                mainContent
            }
            
            // FAB for starting timer
            if timerManager.activeTimer == nil {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingTimerStartSheet = true
                        }) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 56))
                                .foregroundColor(.blue)
                                .background(
                                    Circle()
                                        .fill(circleBackgroundColor)
                                        .frame(width: 60, height: 60)
                                )
                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            
            // Timer Stop Dialog Overlay
            if showingTimerStopDialog, let timer = timerManager.activeTimer {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showingTimerStopDialog = false
                    }
                
                TimerStopDialog(
                    timer: timer,
                    onStop: { description in
                        Task {
                            await stopTimer(description: description)
                        }
                    },
                    onCancel: {
                        showingTimerStopDialog = false
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: timerManager.activeTimer != nil)
        .animation(.easeInOut, value: showingTimerStopDialog)
        .toolbar {
            // Instance Badge (only show when multiple instances)
            if instanceManager.hasMultipleInstances, let activeInstance = instanceManager.activeInstance {
                ToolbarItem(placement: toolbarLeadingPlacement) {
                    Button {
                        showingInstanceSwitcher = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "server.rack")
                                .font(.caption)
                            Text(activeInstance.name)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.timaiHighlight)
                    }
                }
            }
            
            ToolbarItem(placement: toolbarTrailingPlacement) {
                HStack(spacing: 16) {
                    // Suchsymbol mit Badge wenn Filter aktiv sind
                    Button(action: { showingSearchSheet = true }) {
                        ZStack {
                            Image(systemName: "magnifyingglass")
                            
                            if viewModel.searchFilters.hasActiveFilters || !viewModel.searchText.isEmpty {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                    
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
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
                .environmentObject(viewModel)
            }
        }
        .sheet(isPresented: $showingTimerStartSheet) {
            TimerStartSheet(onTimerStarted: {
                // Reload timesheets when timer starts
                Task {
                    await viewModel.loadTimesheets()
                }
            })
            .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showingInstanceSwitcher) {
            InstanceSwitcherSheet()
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showingSearchSheet) {
            SearchSheet(
                searchText: $viewModel.searchText,
                searchFilters: $viewModel.searchFilters
            )
            .environmentObject(authViewModel)
        }
        .onChange(of: viewModel.searchText) { _ in
            viewModel.calculateSections()
        }
        .onChange(of: viewModel.searchFilters) { _ in
            viewModel.calculateSections()
        }
        .task {
            await viewModel.loadTimesheets()
            
            // Sync active timer from server
            if let user = authViewModel.currentUser {
                await timerManager.syncActiveTimerFromServer(user: user)
            }
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
    
    private var mainContent: some View {
        ZStack {
            if viewModel.isLoading && viewModel.activities.isEmpty {
                LoadingView()
            } else if viewModel.filteredActivities.isEmpty && !viewModel.isLoading {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: viewModel.searchFilters.hasActiveFilters || !viewModel.searchText.isEmpty ? "search.noResults".localized() : "Keine Einträge",
                    message: viewModel.searchFilters.hasActiveFilters || !viewModel.searchText.isEmpty ? "search.noResults.message".localized() : "error.message.noTimesheetRecords".localized(),
                    actionTitle: viewModel.searchFilters.hasActiveFilters || !viewModel.searchText.isEmpty ? nil : "Eintrag hinzufügen",
                    action: viewModel.searchFilters.hasActiveFilters || !viewModel.searchText.isEmpty ? nil : { showingAddSheet = true }
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
                                let isPending = viewModel.isPendingSync(activity.recordId)
                                NavigationLink(destination: 
                                    TimesheetDetailView(activity: activity)
                                        .environmentObject(viewModel)
                                ) {
                                    TimesheetRowView(
                                        activity: activity,
                                        isPendingSync: isPending
                                    )
                                }
                                .listRowBackground(
                                    isPending ? 
                                        Color.yellow.opacity(0.08) : 
                                        Color.timaiCardBackground
                                )
                                .contextMenu {
                                    Button {
                                        startTimerForActivity(activity)
                                    } label: {
                                        Label("timer.start.fromEntry".localized(), systemImage: "play.circle")
                                    }
                                    .disabled(timerManager.isTimerRunning)
                                }
                            }
                        }
                    }
                }
                #if os(iOS)
                .listStyle(.insetGrouped)
                #else
                .listStyle(.sidebar)
                #endif
                .background(Color.timaiGray)
                .scrollContentBackground(.hidden)
            }
        }
        .refreshable {
            await viewModel.loadTimesheets()
        }
    }
    
    // MARK: - Timer Actions
    
    private func startTimerForActivity(_ activity: Activity) {
        guard let user = authViewModel.currentUser else { return }
        
            Task {
            do {
                try await timerManager.startTimer(
                    projectId: activity.projectId,
                    projectName: activity.projectName,
                    activityId: activity.activityId,
                    activityName: activity.task,
                    customerId: activity.customerId,
                    customerName: activity.customerName,
                    description: activity.description,
                    user: user
                )
                
                await viewModel.loadTimesheets()
            } catch {
                print("❌ [TimesheetView] Fehler beim Starten des Timers: \(error)")
            }
        }
    }
    
    private func stopTimer(description: String?) async {
        guard let user = authViewModel.currentUser else { return }
        
        do {
            try await timerManager.stopTimer(user: user, finalDescription: description)
            showingTimerStopDialog = false
            await viewModel.loadTimesheets()
        } catch {
            print("❌ [TimesheetView] Fehler beim Stoppen des Timers: \(error)")
            }
        }
    
    // MARK: - Helpers
    
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
    var isPendingSync: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
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
            
            // Sync indicator icon
            if isPendingSync {
                VStack(spacing: 2) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))
                }
                .frame(width: 30)
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

