//
//  ReportType.swift
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

enum ReportType: CaseIterable {
    case userWeek
    case userMonth
    case userYear
    case allUsersWeek
    case allUsersMonth
    case allUsersYear
    case projectDetails
    case projectOverview
    case monthlyEvaluation
    case inactiveProjects
    case projectsByMonthActivityUser
    
    /// Prüft ob dieser Report-Typ die view_other_reporting Berechtigung benötigt
    var requiresViewOtherReporting: Bool {
        switch self {
        case .allUsersWeek, .allUsersMonth, .allUsersYear:
            return true
        default:
            return false
        }
    }
    
    var title: String {
        switch self {
        case .userWeek:
            return "reports.userWeek.title".localized()
        case .userMonth:
            return "reports.userMonth.title".localized()
        case .userYear:
            return "reports.userYear.title".localized()
        case .allUsersWeek:
            return "reports.allUsersWeek.title".localized()
        case .allUsersMonth:
            return "reports.allUsersMonth.title".localized()
        case .allUsersYear:
            return "reports.allUsersYear.title".localized()
        case .projectDetails:
            return "reports.projectDetails.title".localized()
        case .projectOverview:
            return "reports.projectOverview.title".localized()
        case .monthlyEvaluation:
            return "reports.monthlyEvaluation.title".localized()
        case .inactiveProjects:
            return "reports.inactiveProjects.title".localized()
        case .projectsByMonthActivityUser:
            return "reports.projectsByMonthActivityUser.title".localized()
        }
    }
    
    var iconName: String {
        switch self {
        case .userWeek:
            return "calendar.badge.clock"
        case .userMonth:
            return "calendar"
        case .userYear:
            return "calendar.circle"
        case .allUsersWeek:
            return "person.3.fill"
        case .allUsersMonth:
            return "person.3"
        case .allUsersYear:
            return "person.3.sequence"
        case .projectDetails:
            return "doc.text.magnifyingglass"
        case .projectOverview:
            return "list.bullet.rectangle"
        case .monthlyEvaluation:
            return "chart.bar.doc.horizontal"
        case .inactiveProjects:
            return "archivebox"
        case .projectsByMonthActivityUser:
            return "square.grid.3x3"
        }
    }
    
    var description: String {
        switch self {
        case .userWeek:
            return "reports.userWeek.description".localized()
        case .userMonth:
            return "reports.userMonth.description".localized()
        case .userYear:
            return "reports.userYear.description".localized()
        case .allUsersWeek:
            return "reports.allUsersWeek.description".localized()
        case .allUsersMonth:
            return "reports.allUsersMonth.description".localized()
        case .allUsersYear:
            return "reports.allUsersYear.description".localized()
        case .projectDetails:
            return "reports.projectDetails.description".localized()
        case .projectOverview:
            return "reports.projectOverview.description".localized()
        case .monthlyEvaluation:
            return "reports.monthlyEvaluation.description".localized()
        case .inactiveProjects:
            return "reports.inactiveProjects.description".localized()
        case .projectsByMonthActivityUser:
            return "reports.projectsByMonthActivityUser.description".localized()
        }
    }
}


