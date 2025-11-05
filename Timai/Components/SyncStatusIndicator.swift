//
//  SyncStatusIndicator.swift
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

struct SyncStatusIndicator: View {
    @ObservedObject var pendingOpsManager: PendingOperationsManager
    @ObservedObject var syncManager: OfflineSyncManager
    @ObservedObject var networkMonitor: NetworkMonitor
    
    @State private var isRotating = false
    
    var body: some View {
        HStack(spacing: 8) {
            if !networkMonitor.isConnected {
                // Offline indicator
                Image(systemName: "wifi.slash")
                    .foregroundColor(.orange)
                    .font(.system(size: 14, weight: .medium))
            } else if pendingOpsManager.hasPendingOperations {
                // Pending operations indicator
                ZStack {
                    Image(systemName: syncManager.syncStatus.isSyncing ? "arrow.clockwise.circle.fill" : "exclamationmark.icloud.fill")
                        .foregroundColor(syncManager.syncStatus.isSyncing ? .blue : .orange)
                        .font(.system(size: 18, weight: .medium))
                        .rotationEffect(.degrees(isRotating ? 360 : 0))
                        .animation(
                            syncManager.syncStatus.isSyncing ? 
                                Animation.linear(duration: 1.0).repeatForever(autoreverses: false) : 
                                .default,
                            value: isRotating
                        )
                    
                    // Badge with count
                    if pendingOpsManager.pendingCount > 0 && !syncManager.syncStatus.isSyncing {
                        Text("\(pendingOpsManager.pendingCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(3)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 8, y: -8)
                    }
                }
            }
        }
        .onChange(of: syncManager.syncStatus.isSyncing) { isSyncing in
            isRotating = isSyncing
        }
        .onAppear {
            isRotating = syncManager.syncStatus.isSyncing
        }
    }
}

#Preview {
    SyncStatusIndicator(
        pendingOpsManager: PendingOperationsManager.shared,
        syncManager: OfflineSyncManager.shared,
        networkMonitor: NetworkMonitor.shared
    )
}


