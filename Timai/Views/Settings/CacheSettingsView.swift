//
//  CacheSettingsView.swift
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

struct CacheSettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var cacheManager = CacheManager.shared
    @ObservedObject var pendingOpsManager = PendingOperationsManager.shared
    @ObservedObject var syncManager = OfflineSyncManager.shared
    
    @State private var autoSyncEnabled = CacheSettings.autoSyncEnabled
    @State private var maxCacheEntries = CacheSettings.maxCacheEntries
    @State private var cacheRetentionDays = CacheSettings.cacheRetentionDays
    @State private var showClearConfirmation = false
    @State private var showClearSuccess = false
    @State private var isPreloading = false
    @State private var preloadError: String?
    @State private var showPreloadSuccess = false
    
    private var cacheSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: cacheManager.cacheSize)
    }
    
    private var lastSyncFormatted: String {
        guard let lastSync = syncManager.lastSyncDate else {
            return "Nie"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: lastSync, relativeTo: Date())
    }
    
    var body: some View {
        Form {
            // Statistics Section
            Section("cacheSettings.section.statistics".localized()) {
                HStack {
                    Text("cacheSettings.field.cacheSize".localized())
                    Spacer()
                    Text(cacheSizeFormatted)
                        .foregroundColor(.timaiGrayTone2)
                }
                
                HStack {
                    Text("Last Sync")
                    Spacer()
                    Text(lastSyncFormatted)
                        .foregroundColor(.timaiGrayTone2)
                }
                
                if let user = authViewModel.currentUser {
                    let stats = cacheManager.getCacheStatistics(for: user)
                    
                    HStack {
                        Text("cacheSettings.field.timesheets".localized())
                        Spacer()
                        Text("\(stats.timesheetsCount)")
                            .foregroundColor(.timaiGrayTone2)
                    }
                    
                    HStack {
                        Text("cacheSettings.field.customers".localized())
                        Spacer()
                        Text("\(stats.customersCount)")
                            .foregroundColor(.timaiGrayTone2)
                    }
                }
                
                HStack {
                    Text("Ausstehende Änderungen")
                    Spacer()
                    Text("\(pendingOpsManager.pendingCount)")
                        .foregroundColor(pendingOpsManager.hasPendingOperations ? .orange : .timaiGrayTone2)
                }
                
                if pendingOpsManager.failedOperations.count > 0 {
                    HStack {
                        Text("Fehlgeschlagene Ops")
                        Spacer()
                        Text("\(pendingOpsManager.failedOperations.count)")
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Sync Settings Section
            Section("cacheSettings.section.sync".localized()) {
                Toggle("cacheSettings.sync.auto".localized(), isOn: $autoSyncEnabled)
                    .onChange(of: autoSyncEnabled) { newValue in
                        CacheSettings.autoSyncEnabled = newValue
                    }
                
                if let user = authViewModel.currentUser {
                    Button(action: {
                        Task {
                            await syncManager.triggerManualSync(for: user)
                        }
                    }) {
                        HStack {
                            if syncManager.syncStatus.isSyncing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text("Ausstehende Änderungen synchronisieren")
                        }
                    }
                    .disabled(syncManager.syncStatus.isSyncing || !pendingOpsManager.hasPendingOperations)
                    
                    if pendingOpsManager.hasPendingOperations {
                        Button(action: {
                            pendingOpsManager.clearAllOperations()
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Alle ausstehenden Operationen verwerfen")
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
            }
            
            // Reference Data Section
            Section("Referenzdaten") {
                Button(action: {
                    Task {
                        isPreloading = true
                        preloadError = nil
                        do {
                            try await authViewModel.forcePreloadReferenceData()
                            showPreloadSuccess = true
                        } catch {
                            preloadError = error.localizedDescription
                        }
                        isPreloading = false
                    }
                }) {
                    HStack {
                        if isPreloading || authViewModel.isPreloadingData {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.down.circle")
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Alle Daten herunterladen")
                            Text("cacheSettings.sync.preload.subtitle".localized())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .disabled(isPreloading || authViewModel.isPreloadingData)
                
                if let error = preloadError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Cache Settings Section
            Section("cacheSettings.section.settings".localized()) {
                Picker("cacheSettings.field.maxEntries".localized(), selection: $maxCacheEntries) {
                    Text("50").tag(50)
                    Text("100").tag(100)
                    Text("200").tag(200)
                    Text("500").tag(500)
                }
                .onChange(of: maxCacheEntries) { newValue in
                    CacheSettings.maxCacheEntries = newValue
                }
                
                Picker("Aufbewahrungsdauer", selection: $cacheRetentionDays) {
                    Text("7 Tage").tag(7)
                    Text("30 Tage").tag(30)
                    Text("60 Tage").tag(60)
                    Text("90 Tage").tag(90)
                }
                .onChange(of: cacheRetentionDays) { newValue in
                    CacheSettings.cacheRetentionDays = newValue
                }
            }
            
            // Failed Operations Section
            if !pendingOpsManager.failedOperations.isEmpty {
                Section("Fehlgeschlagene Operationen") {
                    ForEach(pendingOpsManager.failedOperations) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.operation.description)
                                .font(.system(size: 14, weight: .medium))
                            
                            if let error = item.lastError {
                                Text(error)
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                            }
                            
                            HStack {
                                Button("Wiederholen") {
                                    pendingOpsManager.retryFailedOperation(item)
                                }
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                                
                                Button("Verwerfen") {
                                    pendingOpsManager.discardFailedOperation(item)
                                }
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            // Danger Zone Section
            Section("Gefahrenzone") {
                Button(action: {
                    showClearConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("cacheSettings.button.clearCache".localized())
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("cacheSettings.navigationTitle".localized())
        .navigationBarTitleDisplayMode(.inline)
        .alert("cacheSettings.alert.clear.title".localized(), isPresented: $showClearConfirmation) {
            Button("Abbrechen", role: .cancel) {}
            Button("Löschen", role: .destructive) {
                Task {
                    if let user = authViewModel.currentUser {
                        try? await cacheManager.clearCache(for: user)
                        showClearSuccess = true
                    }
                }
            }
        } message: {
            Text("Alle gecachten Daten werden gelöscht. Sie benötigen eine Internetverbindung um die Daten neu zu laden.")
        }
        .toast(
            isShowing: $showClearSuccess,
            message: "cacheSettings.toast.cleared".localized(),
            type: .success
        )
        .toast(
            isShowing: $showPreloadSuccess,
            message: "Alle Daten erfolgreich heruntergeladen",
            type: .success
        )
    }
}

#Preview {
    NavigationStack {
        CacheSettingsView()
            .environmentObject(AuthViewModel())
    }
}


