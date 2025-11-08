//
//  TimaiApp.swift
//  Timai
//
//  Copyright © 2018-2025 Timai Contributors.
//  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI
import KeychainAccess

@main
struct TimaiApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var syncManager = OfflineSyncManager.shared
    @StateObject private var biometricService = BiometricAuthService.shared
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        resetStateForUITesting()
        
        // Connect LiveActivityManager to TimerManager
        if #available(iOS 16.2, *) {
            Task { @MainActor in
                TimerManager.shared.setLiveActivityManager(LiveActivityManager.shared)
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(authViewModel)
                    .environmentObject(languageManager)
                    .environmentObject(themeManager)
                    .environmentObject(networkMonitor)
                    .environmentObject(syncManager)
                    .preferredColorScheme(themeManager.currentTheme.colorScheme)
                    .onAppear {
                        Task {
                            await authViewModel.checkAutoLogin()
                        }
                    }
                
                // App Lock Overlay
                if biometricService.isAppLocked && biometricService.isAppLockEnabled {
                    AppLockView()
                        .transition(.opacity)
                        .zIndex(999)
                }
            }
            .onChange(of: scenePhase) { newPhase in
                handleScenePhaseChange(newPhase)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func resetStateForUITesting() {
        if ProcessInfo.processInfo.arguments.contains("UI-Testing") {
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        }
    }
    
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            print("📱 [App] App wird aktiv")
            // App Lock wird nicht automatisch entsperrt - Benutzer muss sich authentifizieren
            
        case .inactive:
            print("📱 [App] App wird inaktiv")
            
        case .background:
            print("📱 [App] App geht in den Hintergrund")
            // Sperre die App, wenn sie in den Hintergrund geht
            biometricService.lockApp()
            
        @unknown default:
            break
        }
    }
}

// MARK: - Content View (Root Navigation)
struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}
