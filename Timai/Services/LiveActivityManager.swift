//
//  LiveActivityManager.swift
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

/// Manages Live Activities for the timer
@available(iOS 16.2, *)
class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private var currentActivityId: String?
    
    private init() {}
    
    /// Start a Live Activity for the running timer
    func startTimerActivity(timer: ActiveTimer) async {
        print("🚀 [LiveActivityManager] startTimerActivity aufgerufen für: \(timer.projectName)")
        
        // Log authorization info for debugging
        let authInfo = ActivityKit.ActivityAuthorizationInfo()
        print("ℹ️ [LiveActivityManager] ActivityKit Status - areActivitiesEnabled: \(authInfo.areActivitiesEnabled), frequentPushesEnabled: \(authInfo.frequentPushesEnabled)")
        
        // Try to start activity - let iOS decide if it's possible
        // Don't block on authorization check as it might be too strict
        
        // Check if an activity already exists
        if let activityId = currentActivityId {
            // Check if activity still exists
            let existingActivities = ActivityKit.Activity<TimerActivityAttributes>.activities
            if existingActivities.contains(where: { $0.id == activityId }) {
                // Update existing activity instead of recreating
                print("🔄 [LiveActivityManager] Live Activity existiert bereits - aktualisiere statt neu zu erstellen")
                await updateTimerActivity(timer: timer)
                return
            } else {
                // Activity doesn't exist anymore, clear the ID
                print("⚠️ [LiveActivityManager] Live Activity mit ID \(activityId) existiert nicht mehr")
                currentActivityId = nil
            }
        }
        
        let attributes = TimerActivityAttributes(
            projectName: timer.projectName,
            activityName: timer.activityName,
            customerName: timer.customerName
        )
        
        // Simple start date - iOS will count up automatically
        let contentState = TimerActivityAttributes.ContentState(
            startDate: timer.startDate,
            lastUpdateTimestamp: Date()
        )
        do {
            let activity = try ActivityKit.Activity.request(
                attributes: attributes,
                content: ActivityContent(state: contentState, staleDate: nil),
                pushType: nil
            )
            
            currentActivityId = activity.id
            print("✅ [LiveActivityManager] Live Activity gestartet: \(activity.id)")
            print("✅ [LiveActivityManager] Activity State: \(activity.activityState)")
            print("✅ [LiveActivityManager] Activity sollte jetzt in Dynamic Island sichtbar sein")
        } catch {
            print("❌ [LiveActivityManager] Fehler beim Starten der Live Activity: \(error)")
            print("❌ [LiveActivityManager] Error Details: \(error.localizedDescription)")
            print("❌ [LiveActivityManager] Error Type: \(type(of: error))")
        }
    }
    
    /// Stop the current Live Activity
    func stopTimerActivity() async {
        guard let activityId = currentActivityId else {
            print("ℹ️ [LiveActivityManager] Keine aktive Live Activity zum Stoppen")
            return
        }
        
        // Find the activity by ID
        for activity in ActivityKit.Activity<TimerActivityAttributes>.activities {
            if activity.id == activityId {
                let finalContent = ActivityContent(
                    state: activity.content.state,
                    staleDate: Date()
                )
                
                await activity.end(finalContent, dismissalPolicy: .immediate)
                currentActivityId = nil
                print("✅ [LiveActivityManager] Live Activity gestoppt")
                return
            }
        }
        
        print("⚠️ [LiveActivityManager] Activity mit ID \(activityId) nicht gefunden")
        currentActivityId = nil
    }
    
    /// Update the Live Activity (if needed)
    func updateTimerActivity(timer: ActiveTimer) async {
        guard let activityId = currentActivityId else {
            print("⚠️ [LiveActivityManager] Keine aktive Live Activity zum Aktualisieren")
            return
        }
        
        // Find the activity by ID
        for activity in ActivityKit.Activity<TimerActivityAttributes>.activities {
            if activity.id == activityId {
                let contentState = TimerActivityAttributes.ContentState(
                    startDate: timer.startDate,
                    lastUpdateTimestamp: Date()
                )
                
                let updatedContent = ActivityContent(
                    state: contentState,
                    staleDate: nil
                )
                
                await activity.update(updatedContent)
                print("✅ [LiveActivityManager] Live Activity aktualisiert")
                return
            }
        }
        
        print("⚠️ [LiveActivityManager] Activity mit ID \(activityId) nicht gefunden")
        print("🔄 [LiveActivityManager] Erstelle neue Live Activity stattdessen...")
        // If not found, create new one
        currentActivityId = nil
        await startTimerActivity(timer: timer)
    }
    
    /// Check if a Live Activity is currently running
    var isActivityRunning: Bool {
        return currentActivityId != nil
    }
}
#else
// macOS stub implementation
class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private init() {}
    
    func startTimerActivity(timer: ActiveTimer) async {
        print("ℹ️ [LiveActivityManager] Live Activities sind nur auf iOS verfügbar")
    }
    
    func stopTimerActivity() async {
        print("ℹ️ [LiveActivityManager] Live Activities sind nur auf iOS verfügbar")
    }
    
    func updateTimerActivity(timer: ActiveTimer) async {
        print("ℹ️ [LiveActivityManager] Live Activities sind nur auf iOS verfügbar")
    }
    
    var isActivityRunning: Bool {
        return false
    }
}
#endif
