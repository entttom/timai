//
//  SettingsView.swift
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

struct SettingsView: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingLogoutAlert = false
    @State private var showingLanguageChangeAlert = false
    @State private var selectedLanguage: AppLanguage
    
    init() {
        _selectedLanguage = State(initialValue: LanguageManager.shared.currentLanguage)
    }
    
    var body: some View {
        List {
            // Appearance Section
            Section("settings.tableView.section.appearance".localized()) {
                Picker("settings.tableView.cell.theme".localized(), selection: $themeManager.currentTheme) {
                    ForEach(AppThemeMode.allCases) { theme in
                        Text(theme.displayName)
                            .tag(theme)
                    }
                }
                .pickerStyle(.menu)
            }
            
            // Language Section
            Section("settings.tableView.section.language".localized()) {
                Picker("settings.tableView.cell.language".localized(), selection: $selectedLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text("\(language.flag) \(language.displayName)")
                            .tag(language)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedLanguage) { newLanguage in
                    if newLanguage != languageManager.currentLanguage {
                        showingLanguageChangeAlert = true
                    }
                }
            }
            
            // Credits Section
            Section("settings.tableView.section.credits".localized()) {
                NavigationLink(destination: OSSCreditsView()) {
                    Label("settings.tableView.cell.openSource".localized(), systemImage: "doc.text")
                }
                
                NavigationLink(destination: GraphicsCreditsView()) {
                    Label("settings.tableView.cell.graphics".localized(), systemImage: "photo")
                }
            }
            
            // About Section
            Section("settings.tableView.section.about".localized()) {
                HStack {
                    Text("settings.tableView.cell.appVersion".localized())
                    Spacer()
                    Text(settingsViewModel.appVersion)
                        .foregroundColor(.timaiGrayTone2)
                }
            }
            
            // Logout Section
            Section {
                Button(role: .destructive, action: { showingLogoutAlert = true }) {
                    HStack {
                        Spacer()
                        Text("settings.button.signout".localized())
                        Spacer()
                    }
                }
            }
            
            // Footer
            Section {
                Text("settings.label.madeBy".localized())
                    .font(.caption)
                    .foregroundColor(.timaiSubheaderColor)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("settings.navigationTitle".localized())
        .alert("settings.alert.logout.title".localized(), isPresented: $showingLogoutAlert) {
            Button("settings.alert.logout.cancel".localized(), role: .cancel) {}
            Button("settings.alert.logout.confirm".localized(), role: .destructive) {
                authViewModel.logout()
            }
        } message: {
            Text("settings.alert.logout.message".localized())
        }
        .alert("settings.alert.language.title".localized(), isPresented: $showingLanguageChangeAlert) {
            Button("settings.alert.language.cancel".localized(), role: .cancel) {
                selectedLanguage = languageManager.currentLanguage
            }
            Button("settings.alert.language.confirm".localized()) {
                languageManager.currentLanguage = selectedLanguage
            }
        } message: {
            Text("settings.alert.language.message".localized())
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(SettingsViewModel())
            .environmentObject(AuthViewModel())
    }
}

