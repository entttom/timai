//
//  SyncStatus.swift
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

enum SyncStatus: Equatable {
    case idle
    case syncing(progress: Double)
    case completed
    case failed(error: String)
    
    var isSyncing: Bool {
        if case .syncing = self {
            return true
        }
        return false
    }
    
    var description: String {
        switch self {
        case .idle:
            return "Bereit"
        case .syncing(let progress):
            return "Synchronisierung läuft... \(Int(progress * 100))%"
        case .completed:
            return "Synchronisiert"
        case .failed(let error):
            return "Fehler: \(error)"
        }
    }
}


