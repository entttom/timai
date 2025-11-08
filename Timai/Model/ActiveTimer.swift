//
//  ActiveTimer.swift
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

/// Represents an active running timer
struct ActiveTimer: Codable, Equatable {
    let timesheetId: Int?  // ID from Kimai server (nil if not yet synced)
    let projectId: Int
    let projectName: String
    let activityId: Int
    let activityName: String
    let customerId: Int
    let customerName: String
    let startDate: Date
    let description: String?
    
    /// Calculate elapsed time from start
    var elapsedTime: TimeInterval {
        return Date().timeIntervalSince(startDate)
    }
    
    /// Format elapsed time as HH:mm:ss
    var formattedElapsedTime: String {
        let elapsed = elapsedTime
        let hours = Int(elapsed) / 3600
        let minutes = (Int(elapsed) % 3600) / 60
        let seconds = Int(elapsed) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

