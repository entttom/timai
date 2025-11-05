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
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @EnvironmentObject var syncManager: OfflineSyncManager
    @StateObject private var timesheetViewModel = TimesheetViewModel()
    @StateObject private var reportsViewModel = ReportsViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var pendingOpsManager = PendingOperationsManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Offline Banner at the top
            OfflineBanner(
                networkMonitor: networkMonitor,
                syncManager: syncManager,
                pendingOpsManager: pendingOpsManager
            )
            
            // Preloading indicator
            PreloadBanner(isLoading: authViewModel.isPreloadingData)
            
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

// MARK: - Preload Banner Component
struct PreloadBanner: View {
    let isLoading: Bool
    
    var body: some View {
        if isLoading {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Lade Referenzdaten")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Kunden, Projekte & Aktivitäten für Offline-Nutzung")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Animated progress indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(0.9)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.12),
                        Color.blue.opacity(0.08)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(height: 1),
                alignment: .bottom
            )
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: isLoading)
        }
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

