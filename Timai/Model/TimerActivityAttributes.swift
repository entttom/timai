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
import ActivityKit

/// Attributes for Timer Live Activity
/// This defines the static data that doesn't change during the activity
struct TimerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic state - the start time for the timer
        var startDate: Date
    }
    
    // Static attributes - don't change during the activity
    var projectName: String
    var activityName: String
    var customerName: String
}

