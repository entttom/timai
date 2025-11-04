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
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(ReportType.allCases, id: \.self) { reportType in
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
        .task {
            await viewModel.loadReportData()
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
    NavigationStack {
        ReportsView()
            .environmentObject(ReportsViewModel())
    }
}

