//
//  ReportsViewModel.swift
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
import SwiftUI

@MainActor
class ReportsViewModel: ObservableObject {
    @Published var timesheets: [Timesheet] = []
    @Published var users: [TimesheetUser] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkService = NetworkService.shared
    private var currentUser: User?
    
    func setUser(_ user: User) {
        self.currentUser = user
    }
    
    func loadReportData() async {
        guard let user = currentUser else {
            print("❌ [ReportsViewModel] Kein User gesetzt")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            async let fetchedTimesheets = networkService.getTimesheetsWithProjects(user)
            async let fetchedUsers = networkService.getAllUsers(user: user)
            
            var loadedTimesheets = try await fetchedTimesheets
            users = try await fetchedUsers
            
            print("✅ [ReportsViewModel] \(loadedTimesheets.count) Timesheets und \(users.count) Users geladen")
            
            // Lade vollständige Projekt-Details mit Budget für alle einzigartigen Projekte
            let uniqueProjectIds = Set(loadedTimesheets.map { $0.project.id })
            print("📊 [ReportsViewModel] Lade Budget-Details für \(uniqueProjectIds.count) Projekte...")
            
            var projectsWithBudget: [Int: Project] = [:]
            
            for projectId in uniqueProjectIds {
                do {
                    let projectWithBudget = try await networkService.getProjectById(projectId, user: user)
                    projectsWithBudget[projectId] = projectWithBudget
                    print("  ✅ \(projectWithBudget.name): Budget=\(projectWithBudget.timeBudget ?? 0)s (\(Double(projectWithBudget.timeBudget ?? 0) / 3600.0)h)")
                } catch {
                    print("  ⚠️ Konnte Budget für Projekt \(projectId) nicht laden: \(error)")
                }
            }
            
            // Ersetze Projekte in Timesheets mit vollständigen Projekt-Objekten (inkl. Budget)
            loadedTimesheets = loadedTimesheets.map { timesheet in
                if let projectWithBudget = projectsWithBudget[timesheet.project.id] {
                    return Timesheet(
                        id: timesheet.id,
                        begin: timesheet.begin,
                        end: timesheet.end,
                        duration: timesheet.duration,
                        user: timesheet.user,
                        activity: timesheet.activity,
                        project: projectWithBudget,  // Vollständiges Projekt mit Budget
                        description: timesheet.description,
                        rate: timesheet.rate,
                        internalRate: timesheet.internalRate,
                        fixedRate: timesheet.fixedRate,
                        hourlyRate: timesheet.hourlyRate,
                        exported: timesheet.exported,
                        billable: timesheet.billable,
                        tags: timesheet.tags
                    )
                }
                return timesheet
            }
            
            timesheets = loadedTimesheets
            print("✅ [ReportsViewModel] Budget-Daten für alle Projekte geladen")
            
        } catch {
            print("❌ [ReportsViewModel] Fehler beim Laden: \(error)")
            errorMessage = "Fehler beim Laden der Report-Daten"
        }
        
        isLoading = false
    }
}

