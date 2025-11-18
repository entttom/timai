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
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct SettingsView: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var biometricService = BiometricAuthService.shared
    @StateObject private var instanceManager = InstanceManager.shared
    @State private var showingLogoutAlert = false
    @State private var showingLanguageChangeAlert = false
    @State private var showingAddInstance = false
    @State private var showingDeleteAlert = false
    @State private var instanceToDelete: KimaiInstance?
    @State private var selectedLanguage: AppLanguage
    
    init() {
        _selectedLanguage = State(initialValue: LanguageManager.shared.currentLanguage)
    }
    
    var body: some View {
        List {
            // Kimai Instances Section
            Section("settings.section.instances".localized()) {
                ForEach(instanceManager.instances) { instance in
                    NavigationLink {
                        EditInstanceView(instance: instance)
                            .environmentObject(authViewModel)
                            .environmentObject(instanceManager)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(instance.name)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Text(instance.apiEndpoint.absoluteString)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            
                            Spacer()
                            
                            if instance.isActive {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.timaiHighlight)
                            }
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            instanceToDelete = instance
                            showingDeleteAlert = true
                        } label: {
                            Label("settings.instances.delete".localized(), systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if !instance.isActive {
                            Button {
                                Task {
                                    await authViewModel.switchToInstance(instance)
                                }
                            } label: {
                                Label("settings.instances.activate".localized(), systemImage: "checkmark.circle")
                            }
                            .tint(.green)
                        }
                    }
                }
                
                Button {
                    showingAddInstance = true
                } label: {
                    Label("settings.instances.addNew".localized(), systemImage: "plus.circle.fill")
                }
            }
            
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
                        Text(language.displayName)
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
            
            // Offline & Cache Section
            Section("settings.section.offlineCache".localized()) {
                NavigationLink(destination: CacheSettingsView()) {
                    Label("settings.cache.management".localized(), systemImage: "externaldrive")
                }
                
                Toggle("settings.cache.autoSync".localized(), isOn: Binding(
                    get: { CacheSettings.autoSyncEnabled },
                    set: { CacheSettings.autoSyncEnabled = $0 }
                ))
            }
            
            // Support Section
            Section("Unterstützung") {
                Button(action: {
                    if let url = URL(string: "https://paypal.me/Entner") {
                        #if os(iOS)
                        UIApplication.shared.open(url)
                        #elseif os(macOS)
                        NSWorkspace.shared.open(url)
                        #endif
                    }
                }) {
                    HStack {
                        Label("Entwickler unterstützen", systemImage: "heart.fill")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.timaiGrayTone2)
                    }
                }
            }
            
            // Security Section
            Section {
                Toggle(isOn: $biometricService.isAppLockEnabled) {
                    HStack(spacing: 12) {
                        Image(systemName: biometricService.biometricType.iconName)
                            .foregroundColor(.timaiHighlight)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("settings.security.appLock".localized())
                                .font(.body)
                            
                            if biometricService.isBiometricAuthAvailable {
                                Text("\("settings.security.appLock.with".localized()) \(biometricService.biometricType.displayName)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("settings.security.appLock.withPasscode".localized())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            } header: {
                Text("settings.section.security".localized())
            } footer: {
                if biometricService.isBiometricAuthAvailable {
                    Text(String(format: "settings.security.appLock.footer.biometric".localized(), biometricService.biometricType.displayName))
                } else {
                    Text("settings.security.appLock.footer.passcode".localized())
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
            
            // Account Section
            if let user = authViewModel.currentUser {
                Section("Account") {
                    // Username
                    if let userDetails = user.userDetails {
                        HStack {
                            Label("Benutzer", systemImage: "person.fill")
                            Spacer()
                            Text(userDetails.username)
                                .foregroundColor(.timaiGrayTone2)
                        }
                        
                        // User ID
                        HStack {
                            Label("User ID", systemImage: "number")
                            Spacer()
                            Text("\(userDetails.id)")
                                .foregroundColor(.timaiGrayTone2)
                        }
                        
                        // Roles
                        if let roles = userDetails.roles, !roles.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Rollen", systemImage: "key.fill")
                                    .foregroundColor(.primary)
                                
                                ForEach(roles, id: \.self) { role in
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.timaiHighlight)
                                            .font(.caption)
                                        Text(formatRoleName(role))
                                            .font(.subheadline)
                                            .foregroundColor(.timaiGrayTone2)
                                        Spacer()
                                    }
                                    .padding(.leading, 24)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // API Endpoint
                    HStack {
                        Label("Server", systemImage: "server.rack")
                        Spacer()
                        Text(user.apiEndpoint.absoluteString)
                            .font(.caption)
                            .foregroundColor(.timaiGrayTone2)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
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
        .alert("settings.alert.logout.title".localized(), isPresented: $showingLogoutAlert) {
            Button("settings.alert.logout.cancel".localized(), role: .cancel) {}
            Button("settings.alert.logout.confirm".localized(), role: .destructive) {
                authViewModel.logout()
            }
        } message: {
            if let activeInstance = instanceManager.activeInstance {
                Text(String(format: "settings.alert.logout.messageWithInstance".localized(), activeInstance.name))
            } else {
                Text("settings.alert.logout.message".localized())
            }
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
        .sheet(isPresented: $showingAddInstance) {
            AddInstanceView()
                .environmentObject(authViewModel)
        }
        .alert("settings.instances.delete.title".localized(), isPresented: $showingDeleteAlert) {
            Button("settings.instances.delete.cancel".localized(), role: .cancel) {
                instanceToDelete = nil
            }
            Button("settings.instances.delete.confirm".localized(), role: .destructive) {
                if let instance = instanceToDelete {
                    Task {
                        do {
                            try await instanceManager.deleteInstance(instance)
                        } catch {
                            print("❌ [SettingsView] Fehler beim Löschen der Instanz: \(error)")
                        }
                    }
                }
                instanceToDelete = nil
            }
        } message: {
            if let instance = instanceToDelete {
                Text(String(format: "settings.instances.delete.message".localized(), instance.name))
            }
        }
    }
    
    // Helper: Format role name for display
    private func formatRoleName(_ role: String) -> String {
        // Entferne "ROLE_" Prefix und mache es lesbarer
        let withoutPrefix = role.replacingOccurrences(of: "ROLE_", with: "")
        
        // Ersetze Unterstriche durch Leerzeichen und kapitalisiere
        let words = withoutPrefix.split(separator: "_")
        return words.map { word in
            word.prefix(1).uppercased() + word.dropFirst().lowercased()
        }.joined(separator: " ")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(SettingsViewModel())
            .environmentObject(AuthViewModel())
            .environmentObject(LanguageManager.shared)
            .environmentObject(ThemeManager.shared)
    }
}

