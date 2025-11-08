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
import Combine

@MainActor
class ReportsViewModel: ObservableObject {
    @Published var timesheets: [Timesheet] = []
    @Published var users: [TimesheetUser] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkService = NetworkService.shared
    private var currentUser: User?
    private var cancellables = Set<AnyCancellable>()
    
    // Cache für lazy-geladene Budget-Daten
    private var projectBudgetCache: [Int: Project] = [:]
    private var loadingProjectIds: Set<Int> = []
    
    init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        // Listen for instance changes
        NotificationCenter.default.publisher(for: .instanceDidChange)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.onInstanceChanged()
                }
            }
            .store(in: &cancellables)
    }
    
    private func onInstanceChanged() {
        print("🔄 [ReportsViewModel] Instanz gewechselt - lösche Cache und lade Daten neu")
        // Clear cache
        projectBudgetCache.removeAll()
        loadingProjectIds.removeAll()
        timesheets.removeAll()
        users.removeAll()
        
        // Reload data
        Task {
            await loadReportData()
        }
    }
    
    func setUser(_ user: User) {
        self.currentUser = user
    }
    
    /// Lazy Loading: Lädt Budget-Daten für ein spezifisches Projekt bei Bedarf
    func loadProjectBudget(for projectId: Int) async -> Project? {
        // Prüfe Cache
        if let cachedProject = projectBudgetCache[projectId] {
            return cachedProject
        }
        
        // Verhindere doppeltes Laden
        guard !loadingProjectIds.contains(projectId) else {
            print("⏳ [ReportsViewModel] Budget für Projekt \(projectId) wird bereits geladen")
            return nil
        }
        
        guard let user = currentUser else {
            print("❌ [ReportsViewModel] Kein User gesetzt - kann Budget nicht laden")
            return nil
        }
        
        loadingProjectIds.insert(projectId)
        
        do {
            let projectWithBudget = try await networkService.getProjectById(projectId, user: user)
            projectBudgetCache[projectId] = projectWithBudget
            loadingProjectIds.remove(projectId)
            print("✅ [ReportsViewModel] Budget geladen für \(projectWithBudget.name): \(projectWithBudget.timeBudget ?? 0)s")
            return projectWithBudget
        } catch {
            loadingProjectIds.remove(projectId)
            print("⚠️ [ReportsViewModel] Konnte Budget für Projekt \(projectId) nicht laden: \(error)")
            return nil
        }
    }
    
    /// Gibt ein Projekt mit Budget aus dem Cache zurück (ohne zu laden)
    func getCachedProjectWithBudget(for projectId: Int) -> Project? {
        return projectBudgetCache[projectId]
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
            
            var loadedTimesheets = try await fetchedTimesheets
            
            // Users optional laden - wenn keine Berechtigung besteht, einfach überspringen
            do {
                users = try await networkService.getAllUsers(user: user)
                print("✅ [ReportsViewModel] \(loadedTimesheets.count) Timesheets und \(users.count) Users geladen")
            } catch {
                print("⚠️ [ReportsViewModel] Users konnten nicht geladen werden (möglicherweise keine Berechtigung): \(error)")
                users = []
                print("✅ [ReportsViewModel] \(loadedTimesheets.count) Timesheets geladen (ohne Users)")
            }
            
            timesheets = loadedTimesheets
            print("✅ [ReportsViewModel] Report-Daten geladen (Budget wird bei Bedarf nachgeladen)")
            
        } catch {
            print("❌ [ReportsViewModel] Fehler beim Laden: \(error)")
            errorMessage = "Fehler beim Laden der Report-Daten"
        }
        
        isLoading = false
    }
}

