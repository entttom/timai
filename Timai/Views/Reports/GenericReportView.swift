//
//  GenericReportView.swift
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
import Charts

// MARK: - User Reports
struct UserWeekReportView: View {
    @EnvironmentObject var viewModel: ReportsViewModel
    
    var body: some View {
        GenericTimeReportView(
            title: "reports.userWeek.title".localized(),
            timesheets: viewModel.timesheets,
            period: .week
        )
        .refreshable {
            await viewModel.loadReportData()
        }
    }
}

struct UserMonthReportView: View {
    @EnvironmentObject var viewModel: ReportsViewModel
    
    var body: some View {
        GenericTimeReportView(
            title: "reports.userMonth.title".localized(),
            timesheets: viewModel.timesheets,
            period: .month
        )
        .refreshable {
            await viewModel.loadReportData()
        }
    }
}

struct UserYearReportView: View {
    @EnvironmentObject var viewModel: ReportsViewModel
    
    var body: some View {
        GenericTimeReportView(
            title: "reports.userYear.title".localized(),
            timesheets: viewModel.timesheets,
            period: .year
        )
        .refreshable {
            await viewModel.loadReportData()
        }
    }
}

// MARK: - All Users Reports
struct AllUsersWeekReportView: View {
    @EnvironmentObject var viewModel: ReportsViewModel
    
    var body: some View {
        AllUsersReportView(
            title: "reports.allUsersWeek.title".localized(),
            users: viewModel.users,
            timesheets: viewModel.timesheets,
            period: .week
        )
        .refreshable {
            await viewModel.loadReportData()
        }
    }
}

struct AllUsersMonthReportView: View {
    @EnvironmentObject var viewModel: ReportsViewModel
    
    var body: some View {
        AllUsersReportView(
            title: "reports.allUsersMonth.title".localized(),
            users: viewModel.users,
            timesheets: viewModel.timesheets,
            period: .month
        )
        .refreshable {
            await viewModel.loadReportData()
        }
    }
}

struct AllUsersYearReportView: View {
    @EnvironmentObject var viewModel: ReportsViewModel
    
    var body: some View {
        AllUsersReportView(
            title: "reports.allUsersYear.title".localized(),
            users: viewModel.users,
            timesheets: viewModel.timesheets,
            period: .year
        )
        .refreshable {
            await viewModel.loadReportData()
        }
    }
}

// MARK: - Project Reports
struct ProjectDetailsReportView: View {
    @EnvironmentObject var viewModel: ReportsViewModel
    
    var body: some View {
        ProjectReportView(
            title: "reports.projectDetails.title".localized(),
            timesheets: viewModel.timesheets
        )
        .refreshable {
            await viewModel.loadReportData()
        }
    }
}

struct ProjectOverviewReportView: View {
    @EnvironmentObject var viewModel: ReportsViewModel
    
    var body: some View {
        ProjectReportView(
            title: "reports.projectOverview.title".localized(),
            timesheets: viewModel.timesheets
        )
        .refreshable {
            await viewModel.loadReportData()
        }
    }
}

struct MonthlyEvaluationReportView: View {
    @EnvironmentObject var viewModel: ReportsViewModel
    
    var body: some View {
        GenericTimeReportView(
            title: "reports.monthlyEvaluation.title".localized(),
            timesheets: viewModel.timesheets,
            period: .month
        )
        .refreshable {
            await viewModel.loadReportData()
        }
    }
}

struct InactiveProjectsReportView: View {
    @EnvironmentObject var viewModel: ReportsViewModel
    
    var body: some View {
        InactiveProjectsListView(
            title: "reports.inactiveProjects.title".localized(),
            timesheets: viewModel.timesheets
        )
        .refreshable {
            await viewModel.loadReportData()
        }
    }
}

struct ProjectsByMonthActivityUserReportView: View {
    @EnvironmentObject var viewModel: ReportsViewModel
    
    var body: some View {
        ProjectReportView(
            title: "reports.projectsByMonthActivityUser.title".localized(),
            timesheets: viewModel.timesheets
        )
        .refreshable {
            await viewModel.loadReportData()
        }
    }
}

// MARK: - Generic Report Components

struct GenericTimeReportView: View {
    let title: String
    let timesheets: [Timesheet]
    let period: TimePeriod
    
    @State private var selectedDate = Date()
    
    private var toolbarTrailingPlacement: ToolbarItemPlacement {
        #if os(iOS)
        return .navigationBarTrailing
        #else
        return .automatic
        #endif
    }
    
    enum TimePeriod {
        case week, month, year
    }
    
    // Berechne dateRange nur einmal beim Erstellen
    private let dateRange: ClosedRange<Date>
    
    init(title: String, timesheets: [Timesheet], period: TimePeriod) {
        self.title = title
        self.timesheets = timesheets
        self.period = period
        
        // Berechne die Range nur einmal
        let dates = timesheets.map { $0.begin }
        let minDate = dates.min() ?? Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        let maxDate = dates.max() ?? Date()
        self.dateRange = minDate...maxDate
    }
    
    var filteredTimesheets: [Timesheet] {
        return timesheets.filter { timesheet in
            switch period {
            case .week:
                return Calendar.current.isDate(timesheet.begin, equalTo: selectedDate, toGranularity: .weekOfYear)
            case .month:
                return Calendar.current.isDate(timesheet.begin, equalTo: selectedDate, toGranularity: .month)
            case .year:
                return Calendar.current.isDate(timesheet.begin, equalTo: selectedDate, toGranularity: .year)
            }
        }
    }
    
    var totalHours: Double {
        let totalSeconds = filteredTimesheets.reduce(0) { sum, timesheet in
            sum + (timesheet.duration ?? 0)
        }
        return Double(totalSeconds) / 3600.0
    }
    
    var projectBreakdown: [(String, Double)] {
        var breakdown: [String: Double] = [:]
        for timesheet in filteredTimesheets {
            let projectName = timesheet.project.name
            let hours = Double(timesheet.duration ?? 0) / 3600.0
            breakdown[projectName, default: 0] += hours
        }
        return breakdown.sorted { $0.value > $1.value }
    }
    
    var body: some View {
        List {
            // Period Selector Section
            Section {
                VStack(spacing: 8) {
                    HStack {
                        Text(periodLabel)
                            .font(.subheadline)
                            .foregroundColor(.timaiSubheaderColor)
                        Spacer()
                    }
                    
                    HStack {
                        Button(action: { 
                            withAnimation {
                                movePeriod(by: -1)
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.timaiHighlight)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        DatePicker(
                            "",
                            selection: $selectedDate,
                            in: dateRange,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .id(selectedDate) // Force refresh
                        
                        Spacer()
                        
                        Button(action: { 
                            withAnimation {
                                movePeriod(by: 1)
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.timaiHighlight)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .disabled(!canMoveForward)
                    }
                }
            }
            
            // Summary Section
            Section("reports.section.summary".localized()) {
                HStack {
                    Text("reports.field.totalHours".localized())
                        .foregroundColor(.timaiSubheaderColor)
                    Spacer()
                    Text(String(format: "%.2f h", totalHours))
                        .fontWeight(.bold)
                        .foregroundColor(.timaiHighlight)
                }
                
                HStack {
                    Text("reports.field.entryCount".localized())
                        .foregroundColor(.timaiSubheaderColor)
                    Spacer()
                    Text("\(filteredTimesheets.count)")
                        .fontWeight(.bold)
                        .foregroundColor(.timaiTextBlack)
                }
            }
            
            // Chart Section
            if !projectBreakdown.isEmpty {
                Section("reports.section.byProject".localized()) {
                    Chart(projectBreakdown, id: \.0) { item in
                        BarMark(
                            x: .value("Stunden", item.1),
                            y: .value("Projekt", item.0)
                        )
                        .foregroundStyle(Color.timaiHighlight)
                    }
                    .frame(height: CGFloat(projectBreakdown.count * 40))
                    .padding(.vertical)
                }
            }
            
            // Project List
            Section("reports.section.details".localized()) {
                ForEach(projectBreakdown, id: \.0) { project, hours in
                    HStack {
                        Text(project)
                        Spacer()
                        Text(String(format: "%.2f h", hours))
                            .foregroundColor(.timaiGrayTone2)
                    }
                }
            }
        }
        .navigationTitle(title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: toolbarTrailingPlacement) {
                Button("Heute") {
                    selectedDate = Date()
                }
                .font(.subheadline)
            }
        }
    }
    
    // Helper: Zeitraum-Label
    private var periodLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        switch period {
        case .week:
            formatter.dateFormat = "EEEE, d. MMM yyyy"
            let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
            return "KW \(Calendar.current.component(.weekOfYear, from: selectedDate)) - \(formatter.string(from: weekStart))"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: selectedDate)
        case .year:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: selectedDate)
        }
    }
    
    // Helper: Bewege Zeitraum vor/zurück
    private func movePeriod(by offset: Int) {
        let calendar = Calendar.current
        guard let newDate = {
            switch period {
            case .week:
                return calendar.date(byAdding: .weekOfYear, value: offset, to: selectedDate)
            case .month:
                return calendar.date(byAdding: .month, value: offset, to: selectedDate)
            case .year:
                return calendar.date(byAdding: .year, value: offset, to: selectedDate)
            }
        }() else { return }
        
        // Stelle sicher, dass das neue Datum im erlaubten Bereich liegt
        if dateRange.contains(newDate) {
            selectedDate = newDate
        }
    }
    
    // Helper: Kann nicht weiter in die Zukunft
    private var canMoveForward: Bool {
        let calendar = Calendar.current
        switch period {
        case .week:
            let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
            return !calendar.isDate(nextWeek, equalTo: Date(), toGranularity: .weekOfYear) && nextWeek <= Date()
        case .month:
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
            return !calendar.isDate(nextMonth, equalTo: Date(), toGranularity: .month) && nextMonth <= Date()
        case .year:
            let nextYear = calendar.date(byAdding: .year, value: 1, to: selectedDate) ?? selectedDate
            return !calendar.isDate(nextYear, equalTo: Date(), toGranularity: .year) && nextYear <= Date()
        }
    }
}

struct AllUsersReportView: View {
    let title: String
    let users: [TimesheetUser]
    let timesheets: [Timesheet]
    let period: GenericTimeReportView.TimePeriod
    
    @State private var selectedDate = Date()
    
    // Berechne dateRange nur einmal beim Erstellen
    private let dateRange: ClosedRange<Date>
    
    init(title: String, users: [TimesheetUser], timesheets: [Timesheet], period: GenericTimeReportView.TimePeriod) {
        self.title = title
        self.users = users
        self.timesheets = timesheets
        self.period = period
        
        // Berechne die Range nur einmal
        let dates = timesheets.map { $0.begin }
        let minDate = dates.min() ?? Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        let maxDate = dates.max() ?? Date()
        self.dateRange = minDate...maxDate
    }
    
    var userBreakdown: [(TimesheetUser, Double)] {
        var breakdown: [Int: Double] = [:]
        let filteredTimesheets = filterTimesheets()
        
        for timesheet in filteredTimesheets {
            let userId = timesheet.user.id
            let hours = Double(timesheet.duration ?? 0) / 3600.0
            breakdown[userId, default: 0] += hours
        }
        
        return users.compactMap { user in
            if let hours = breakdown[user.id] {
                return (user, hours)
            }
            return nil
        }.sorted { $0.1 > $1.1 }
    }
    
    func filterTimesheets() -> [Timesheet] {
        return timesheets.filter { timesheet in
            switch period {
            case .week:
                return Calendar.current.isDate(timesheet.begin, equalTo: selectedDate, toGranularity: .weekOfYear)
            case .month:
                return Calendar.current.isDate(timesheet.begin, equalTo: selectedDate, toGranularity: .month)
            case .year:
                return Calendar.current.isDate(timesheet.begin, equalTo: selectedDate, toGranularity: .year)
            }
        }
    }
    
    var body: some View {
        List {
            Section("reports.section.byUser".localized()) {
                ForEach(userBreakdown, id: \.0.id) { user, hours in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(user.username)
                                .font(.headline)
                            if let alias = user.alias {
                                Text(alias)
                                    .font(.caption)
                                    .foregroundColor(.timaiSubheaderColor)
                            }
                        }
                        Spacer()
                        Text(String(format: "%.2f h", hours))
                            .fontWeight(.semibold)
                            .foregroundColor(.timaiHighlight)
                    }
                }
            }
        }
        .navigationTitle(title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct ProjectReportView: View {
    let title: String
    let timesheets: [Timesheet]
    
    @EnvironmentObject var viewModel: ReportsViewModel
    @State private var projectsWithBudget: [Int: Project] = [:]
    
    var projectData: [(Project, Int, Double)] {
        var breakdown: [Int: (Project, Int, Double)] = [:]
        
        for timesheet in timesheets {
            let projectId = timesheet.project.id
            let hours = Double(timesheet.duration ?? 0) / 3600.0
            
            // Verwende Projekt mit Budget falls vorhanden, sonst Original
            let projectToUse = projectsWithBudget[projectId] ?? timesheet.project
            
            if var existing = breakdown[projectId] {
                existing.1 += 1  // count
                existing.2 += hours
                breakdown[projectId] = existing
            } else {
                breakdown[projectId] = (projectToUse, 1, hours)
            }
        }
        
        return breakdown.values.sorted { $0.2 > $1.2 }
    }
    
    var body: some View {
        List {
            ForEach(projectData, id: \.0.id) { project, count, hours in
                ProjectRowView(
                    project: project,
                    count: count,
                    hours: hours,
                    viewModel: viewModel,
                    projectsWithBudget: $projectsWithBudget
                )
            }
        }
        .navigationTitle(title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .refreshable {
            await viewModel.loadReportData()
        }
    }
}

struct ProjectRowView: View {
    let project: Project
    let count: Int
    let hours: Double
    let viewModel: ReportsViewModel
    @Binding var projectsWithBudget: [Int: Project]
    
    @State private var isLoadingBudget = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(project.name)
                .font(.headline)
                .foregroundColor(.timaiTextBlack)
            
            Text(project.customer.name)
                .font(.subheadline)
                .foregroundColor(.timaiSubheaderColor)
            
            HStack {
                Label("\(count) " + "reports.field.entries".localized(), systemImage: "list.bullet")
                    .font(.caption)
                    .foregroundColor(.timaiGrayTone2)
                
                Spacer()
                
                Text(String(format: "%.2f h", hours))
                    .fontWeight(.semibold)
                    .foregroundColor(.timaiHighlight)
            }
            
            // Budget Information
            if let timeBudget = project.timeBudget, timeBudget > 0 {
                let budgetHours = Double(timeBudget) / 3600.0
                let progress = hours / budgetHours
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("reports.field.budget".localized() + ":")
                            .font(.caption)
                            .foregroundColor(.timaiGrayTone2)
                        
                        Spacer()
                        
                        Text(String(format: "%.2f / %.2f h", hours, budgetHours))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(progress > 1.0 ? .red : .timaiGrayTone3)
                        
                        Text(String(format: "(%.0f%%)", progress * 100))
                            .font(.caption)
                            .foregroundColor(progress > 1.0 ? .red : .timaiGrayTone2)
                    }
                    
                    // Progress Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.timaiGrayTone1)
                                .frame(height: 8)
                            
                            // Progress
                            RoundedRectangle(cornerRadius: 4)
                                .fill(progress > 1.0 ? Color.red : Color.timaiHighlight)
                                .frame(width: min(geometry.size.width * progress, geometry.size.width), height: 8)
                        }
                    }
                    .frame(height: 8)
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
        .task {
            // Lazy Loading: Budget nur laden wenn noch nicht im Cache
            guard projectsWithBudget[project.id] == nil else { return }
            guard !isLoadingBudget else { return }
            
            isLoadingBudget = true
            if let projectWithBudget = await viewModel.loadProjectBudget(for: project.id) {
                projectsWithBudget[project.id] = projectWithBudget
            }
            isLoadingBudget = false
        }
    }
}

struct InactiveProjectsListView: View {
    let title: String
    let timesheets: [Timesheet]
    
    var inactiveProjects: [Project] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let activeProjectIds = Set(timesheets.filter { $0.begin > thirtyDaysAgo }.map { $0.project.id })
        let allProjects = Set(timesheets.map { $0.project })
        
        return allProjects.filter { !activeProjectIds.contains($0.id) }.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        List {
            if inactiveProjects.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "reports.projects.inactive.empty.title".localized(),
                    message: "reports.projects.inactive.empty.message".localized()
                )
            } else {
                ForEach(inactiveProjects) { project in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.name)
                            .font(.headline)
                        Text(project.customer.name)
                            .font(.caption)
                            .foregroundColor(.timaiSubheaderColor)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle(title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

