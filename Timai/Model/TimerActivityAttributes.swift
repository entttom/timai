//
//  TimerActivityAttributes.swift
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

#if os(iOS)
import ActivityKit

/// Attributes for Timer Live Activity
/// This defines the static data that doesn't change during the activity
struct TimerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Timer start date - iOS calculates elapsed time automatically
        var startDate: Date
        // Dummy field that changes to force iOS to recognize state updates
        var lastUpdateTimestamp: Date
    }
    
    // Static attributes - don't change during the activity
    var projectName: String
    var activityName: String
    var customerName: String
}
#endif

