//
//  ReportsView.swift
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

struct ReportsView: View {
    @EnvironmentObject var viewModel: ReportsViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var instanceManager = InstanceManager.shared
    @State private var showingInstanceSwitcher = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(availableReports, id: \.self) { reportType in
                    NavigationLink(destination: reportDestination(for: reportType)) {
                        ReportCardView(reportType: reportType)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
        .background(Color.timaiGray.ignoresSafeArea())
        .navigationTitle("reports.navigationTitle".localized())
        .toolbar {
            // Instance Badge (only show when multiple instances)
            if instanceManager.hasMultipleInstances, let activeInstance = instanceManager.activeInstance {
                ToolbarItem(placement: .navigationBarLeading) {
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
        }
        .sheet(isPresented: $showingInstanceSwitcher) {
            InstanceSwitcherSheet()
                .environmentObject(authViewModel)
        }
        .task {
            await viewModel.loadReportData()
        }
    }
    
    /// Filtert die verfügbaren Reports basierend auf den Berechtigungen des Users
    private var availableReports: [ReportType] {
        guard let user = authViewModel.currentUser else {
            return []
        }
        
        // Prüfe ob User die view_other_reporting Berechtigung hat
        let hasViewOtherReporting = user.userDetails?.hasAnyRole([
            "ROLE_SUPER_ADMIN",  // Super-Admin hat immer alle Rechte
            "ROLE_ADMIN"         // Admin hat normalerweise auch view_other_reporting
        ]) ?? false
        
        // Wenn User keine view_other_reporting Berechtigung hat, filtere entsprechende Reports aus
        return ReportType.allCases.filter { reportType in
            if reportType.requiresViewOtherReporting {
                return hasViewOtherReporting
            }
            return true
        }
    }
    
    @ViewBuilder
    private func reportDestination(for type: ReportType) -> some View {
        switch type {
        case .userWeek:
            UserWeekReportView()
                .environmentObject(viewModel)
        case .userMonth:
            UserMonthReportView()
                .environmentObject(viewModel)
        case .userYear:
            UserYearReportView()
                .environmentObject(viewModel)
        case .allUsersWeek:
            AllUsersWeekReportView()
                .environmentObject(viewModel)
        case .allUsersMonth:
            AllUsersMonthReportView()
                .environmentObject(viewModel)
        case .allUsersYear:
            AllUsersYearReportView()
                .environmentObject(viewModel)
        case .projectDetails:
            ProjectDetailsReportView()
                .environmentObject(viewModel)
        case .projectOverview:
            ProjectOverviewReportView()
                .environmentObject(viewModel)
        case .monthlyEvaluation:
            MonthlyEvaluationReportView()
                .environmentObject(viewModel)
        case .inactiveProjects:
            InactiveProjectsReportView()
                .environmentObject(viewModel)
        case .projectsByMonthActivityUser:
            ProjectsByMonthActivityUserReportView()
                .environmentObject(viewModel)
        }
    }
}

struct ReportCardView: View {
    let reportType: ReportType
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: reportType.iconName)
                .font(.title)
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    LinearGradient(
                        colors: [Color.timaiHighlight, Color.timaiHighlight.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
            
            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(reportType.title)
                    .font(.headline)
                    .foregroundColor(.timaiTextBlack)
                
                Text(reportType.description)
                    .font(.caption)
                    .foregroundColor(.timaiSubheaderColor)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .foregroundColor(.timaiGrayTone2)
                .font(.caption)
        }
        .padding()
        .background(Color.timaiCardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Report Type Enum Extension
extension ReportType: Hashable {}

#Preview {
    let authViewModel = AuthViewModel()
    authViewModel.isAuthenticated = true
    authViewModel.currentUser = User(
        apiEndpoint: URL(string: "https://demo.kimai.org/api")!,
        apiToken: "token_admin"
    )
    
    return NavigationStack {
        ReportsView()
            .environmentObject(ReportsViewModel())
            .environmentObject(authViewModel)
    }
}

