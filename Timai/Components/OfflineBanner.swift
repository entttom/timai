//
//  OfflineBanner.swift
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

struct OfflineBanner: View {
    @ObservedObject var networkMonitor: NetworkMonitor
    @ObservedObject var syncManager: OfflineSyncManager
    @ObservedObject var pendingOpsManager: PendingOperationsManager
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var showBanner = false
    
    var body: some View {
        VStack(spacing: 0) {
            if !networkMonitor.isConnected {
                HStack(spacing: 12) {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Offline-Modus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if pendingOpsManager.hasPendingOperations {
                            Text("\(pendingOpsManager.pendingCount) ausstehende Änderungen")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    
                    Spacer()
                    
                    // Sync button (disabled when offline)
                    Button(action: {
                        // Disabled when offline
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.system(size: 14, weight: .medium))
                    }
                    .disabled(true)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.orange)
                .transition(.move(edge: .top).combined(with: .opacity))
            } else if networkMonitor.isConnected && pendingOpsManager.hasPendingOperations {
                // Show sync banner when online with pending operations
                HStack(spacing: 12) {
                    if syncManager.syncStatus.isSyncing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "exclamationmark.icloud")
                            .foregroundColor(.orange)
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(syncManager.syncStatus.isSyncing ? "Synchronisierung..." : "Ausstehende Änderungen")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Text("\(pendingOpsManager.pendingCount) \(pendingOpsManager.pendingCount == 1 ? "Eintrag" : "Einträge") nicht synchronisiert")
                            .font(.system(size: 12))
                            .foregroundColor(.black.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    // Sync button
                    Button(action: {
                        Task {
                            if let user = authViewModel.currentUser {
                                await syncManager.triggerManualSync(for: user)
                            }
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.black)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .disabled(syncManager.syncStatus.isSyncing)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.yellow.opacity(0.9))
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
        .animation(.easeInOut(duration: 0.3), value: pendingOpsManager.hasPendingOperations)
        .onAppear {
            print("🔔 [OfflineBanner] Appeared - Pending: \(pendingOpsManager.hasPendingOperations), Count: \(pendingOpsManager.pendingCount)")
            print("🔔 [OfflineBanner] Network: \(networkMonitor.isConnected ? "Online" : "Offline")")
        }
        .onChange(of: pendingOpsManager.hasPendingOperations) { hasPending in
            print("🔔 [OfflineBanner] Pending Operations geändert: \(hasPending) (\(pendingOpsManager.pendingCount) ops)")
        }
        .onChange(of: networkMonitor.isConnected) { connected in
            print("🔔 [OfflineBanner] Netzwerk-Status geändert: \(connected ? "Online" : "Offline")")
        }
        .onChange(of: pendingOpsManager.pendingCount) { count in
            print("🔔 [OfflineBanner] Pending Count geändert: \(count)")
        }
    }
}

#Preview {
    VStack {
        OfflineBanner(
            networkMonitor: NetworkMonitor.shared,
            syncManager: OfflineSyncManager.shared,
            pendingOpsManager: PendingOperationsManager.shared
        )
        .environmentObject(AuthViewModel())
        
        Spacer()
    }
}


