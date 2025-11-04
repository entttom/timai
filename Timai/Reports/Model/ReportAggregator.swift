//
//  ReportAggregator.swift
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

class ReportAggregator {
    
    // MARK: - Date Range Helpers
    
    static func getCurrentWeekRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let daysToMonday = (weekday == 1) ? -6 : 2 - weekday
        
        guard let monday = calendar.date(byAdding: .day, value: daysToMonday, to: now),
              let startOfMonday = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: monday),
              let endOfSunday = calendar.date(byAdding: .day, value: 6, to: startOfMonday),
              let endOfWeek = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endOfSunday) else {
            return (now, now)
        }
        
        return (startOfMonday, endOfWeek)
    }
    
    static func getCurrentMonthRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth),
              let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endOfMonth) else {
            return (now, now)
        }
        
        return (startOfMonth, endOfDay)
    }
    
    static func getCurrentYearRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        guard let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now)),
              let endOfYear = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: startOfYear),
              let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endOfYear) else {
            return (now, now)
        }
        
        return (startOfYear, endOfDay)
    }
    
    // MARK: - Filtering
    
    static func filterActivities(_ activities: [Activity], from startDate: Date, to endDate: Date) -> [Activity] {
        return activities.filter { activity in
            let start = activity.startDateTime
            return start >= startDate && start <= endDate
        }
    }
    
    static func filterActivitiesByUser(_ activities: [Activity], userId: Int?) -> [Activity] {
        guard let userId = userId else { return activities }
        // Note: Activity model needs to be extended with userId field
        return activities
    }
    
    // MARK: - Aggregation
    
    static func calculateTotalDuration(_ activities: [Activity]) -> TimeInterval {
        return activities.reduce(0) { total, activity in
            let start = activity.startDateTime
            let end = activity.endDateTime
            return total + end.timeIntervalSince(start)
        }
    }
    
    static func groupByProject(_ activities: [Activity]) -> [String: [Activity]] {
        return Dictionary(grouping: activities) { $0.projectName }
    }
    
    static func groupByCustomer(_ activities: [Activity]) -> [String: [Activity]] {
        return Dictionary(grouping: activities) { $0.customerName }
    }
    
    static func groupByTask(_ activities: [Activity]) -> [String: [Activity]] {
        return Dictionary(grouping: activities) { $0.task }
    }
    
    static func groupByDate(_ activities: [Activity]) -> [Date: [Activity]] {
        let calendar = Calendar.current
        return Dictionary(grouping: activities) { activity in
            let date = activity.startDateTime
            return calendar.startOfDay(for: date)
        }
    }
    
    // MARK: - Report Generation
    
    static func generateWeekReport(for activities: [Activity]) -> ReportData {
        let weekRange = getCurrentWeekRange()
        let filteredActivities = filterActivities(activities, from: weekRange.start, to: weekRange.end)
        
        let groupedByDay = groupByDate(filteredActivities)
        let sortedDays = groupedByDay.keys.sorted()
        
        let entries = sortedDays.map { date -> ReportEntry in
            let dayActivities = groupedByDay[date] ?? []
            let duration = calculateTotalDuration(dayActivities)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE, dd.MM.yyyy"
            
            return ReportEntry(
                title: dateFormatter.string(from: date),
                subtitle: "\(dayActivities.count) Einträge",
                duration: duration,
                projectName: nil,
                customerName: nil,
                userName: nil,
                activityName: nil,
                date: date
            )
        }
        
        return ReportData(
            title: "Wochenbericht",
            totalDuration: calculateTotalDuration(filteredActivities),
            entries: entries,
            startDate: weekRange.start,
            endDate: weekRange.end
        )
    }
    
    static func generateMonthReport(for activities: [Activity]) -> ReportData {
        let monthRange = getCurrentMonthRange()
        let filteredActivities = filterActivities(activities, from: monthRange.start, to: monthRange.end)
        
        let groupedByProject = groupByProject(filteredActivities)
        
        let entries = groupedByProject.map { projectName, projectActivities -> ReportEntry in
            let duration = calculateTotalDuration(projectActivities)
            let customerName = projectActivities.first?.customerName ?? ""
            
            return ReportEntry(
                title: projectName,
                subtitle: customerName,
                duration: duration,
                projectName: projectName,
                customerName: customerName,
                userName: nil,
                activityName: nil,
                date: nil
            )
        }.sorted { $0.duration > $1.duration }
        
        return ReportData(
            title: "Monatsbericht",
            totalDuration: calculateTotalDuration(filteredActivities),
            entries: entries,
            startDate: monthRange.start,
            endDate: monthRange.end
        )
    }
    
    static func generateYearReport(for activities: [Activity]) -> ReportData {
        let yearRange = getCurrentYearRange()
        let filteredActivities = filterActivities(activities, from: yearRange.start, to: yearRange.end)
        
        let calendar = Calendar.current
        var monthlyData: [Int: [Activity]] = [:]
        
        for activity in filteredActivities {
            let date = activity.startDateTime
            let month = calendar.component(.month, from: date)
            monthlyData[month, default: []].append(activity)
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        
        let entries = monthlyData.sorted(by: { $0.key < $1.key }).map { month, monthActivities -> ReportEntry in
            let duration = calculateTotalDuration(monthActivities)
            let date = calendar.date(from: DateComponents(year: calendar.component(.year, from: Date()), month: month)) ?? Date()
            
            return ReportEntry(
                title: dateFormatter.string(from: date),
                subtitle: "\(monthActivities.count) Einträge",
                duration: duration,
                projectName: nil,
                customerName: nil,
                userName: nil,
                activityName: nil,
                date: date
            )
        }
        
        return ReportData(
            title: "Jahresbericht",
            totalDuration: calculateTotalDuration(filteredActivities),
            entries: entries,
            startDate: yearRange.start,
            endDate: yearRange.end
        )
    }
    
    static func generateProjectOverview(for activities: [Activity], timesheets: [Timesheet] = []) -> [ProjectReportData] {
        let groupedByProject = groupByProject(activities)
        
        return groupedByProject.map { projectName, projectActivities -> ProjectReportData in
            let duration = calculateTotalDuration(projectActivities)
            let customerName = projectActivities.first?.customerName ?? ""
            let lastActivity = projectActivities.map { $0.startDateTime }.max()
            
            // Finde das passende Projekt für Budget-Informationen aus den Timesheets
            let project = timesheets.first { $0.project.name == projectName }?.project
            let timeBudget = project?.timeBudget.map { TimeInterval($0) }
            let budgetType = project?.budgetType
            
            return ProjectReportData(
                projectName: projectName,
                customerName: customerName,
                totalDuration: duration,
                isActive: true,
                lastActivity: lastActivity,
                entriesCount: projectActivities.count,
                timeBudget: timeBudget,
                budgetType: budgetType
            )
        }.sorted { $0.totalDuration > $1.totalDuration }
    }
    
    static func findInactiveProjects(for activities: [Activity], timesheets: [Timesheet] = [], daysThreshold: Int = 30) -> [ProjectReportData] {
        let calendar = Calendar.current
        let thresholdDate = calendar.date(byAdding: .day, value: -daysThreshold, to: Date()) ?? Date()
        
        let projectOverview = generateProjectOverview(for: activities, timesheets: timesheets)
        
        return projectOverview.filter { project in
            guard let lastActivity = project.lastActivity else { return true }
            return lastActivity < thresholdDate
        }.map { project in
            ProjectReportData(
                projectName: project.projectName,
                customerName: project.customerName,
                totalDuration: project.totalDuration,
                isActive: false,
                lastActivity: project.lastActivity,
                entriesCount: project.entriesCount,
                timeBudget: project.timeBudget,
                budgetType: project.budgetType
            )
        }
    }
}

