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
    
    init() {
        resetStateForUITesting()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(languageManager)
                .onAppear {
                    Task {
                        await authViewModel.checkAutoLogin()
                    }
                }
        }
    }
    
    // MARK: - Helper Methods
    private func resetStateForUITesting() {
        if ProcessInfo.processInfo.arguments.contains("UI-Testing") {
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
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
