//
//  ReportData.swift
//  Timai
//
//  Copyright (c) 2025 Dr. Thomas Entner.
//  All rights reserved.
//
//  Licensed under the Business Source License 1.1.
//  Usage is free for non-commercial and personal use.
//  Commercial use requires a commercial license.
//
import Foundation

struct ReportData {
    var title: String
    var totalDuration: TimeInterval
    var entries: [ReportEntry]
    var startDate: Date
    var endDate: Date
}

struct ReportEntry {
    var title: String
    var subtitle: String?
    var duration: TimeInterval
    var projectName: String?
    var customerName: String?
    var userName: String?
    var activityName: String?
    var date: Date?
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        return String(format: "%dh %02dm", hours, minutes)
    }
}

struct ProjectReportData {
    var projectName: String
    var customerName: String
    var totalDuration: TimeInterval
    var isActive: Bool
    var lastActivity: Date?
    var entriesCount: Int
    var timeBudget: TimeInterval?
    var budgetType: String?
    
    var budgetUsagePercent: Double? {
        guard let budget = timeBudget, budget > 0 else { return nil }
        return (totalDuration / budget) * 100.0
    }
    
    var remainingBudget: TimeInterval? {
        guard let budget = timeBudget else { return nil }
        return budget - totalDuration
    }
}

struct UserReportData {
    var userName: String
    var totalDuration: TimeInterval
    var projectsWorked: Set<String>
    var entriesCount: Int
}

