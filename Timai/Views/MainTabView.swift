//
//  MainTabView.swift
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

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var timesheetViewModel = TimesheetViewModel()
    @StateObject private var reportsViewModel = ReportsViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    
    var body: some View {
        TabView {
            // Zeiterfassung Tab
            NavigationStack {
                TimesheetView()
                    .environmentObject(timesheetViewModel)
            }
            .tabItem {
                Image(systemName: "clock.badge.checkmark")
                Text("Zeiterfassung")
            }
            
            // Reports Tab
            NavigationStack {
                ReportsView()
                    .environmentObject(reportsViewModel)
            }
            .tabItem {
                Image(systemName: "chart.bar.fill")
                Text("reports.tabTitle".localized())
            }
            
            // Einstellungen Tab
            NavigationStack {
                SettingsView()
                    .environmentObject(settingsViewModel)
            }
            .tabItem {
                Image(systemName: "slider.horizontal.3")
                Text("Einstellungen")
            }
        }
        .accentColor(.timaiHighlight)
        .onAppear {
            setupTabBarAppearance()
            
            // Set current user for view models
            if let user = authViewModel.currentUser {
                timesheetViewModel.setUser(user)
                reportsViewModel.setUser(user)
            }
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 44/255, green: 44/255, blue: 46/255, alpha: 0.95)
            default:
                return UIColor.white.withAlphaComponent(0.95)
            }
        }
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().isTranslucent = true
    }
}

#Preview {
    let authViewModel = AuthViewModel()
    authViewModel.isAuthenticated = true
    authViewModel.currentUser = User(
        apiEndpoint: URL(string: "https://demo.kimai.org/api")!,
        apiToken: "test_token"
    )
    
    return MainTabView()
        .environmentObject(authViewModel)
}

