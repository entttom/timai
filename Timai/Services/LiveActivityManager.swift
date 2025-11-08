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
#if canImport(ActivityKit)
import ActivityKit
#endif

/// Manages Live Activities for the timer
@available(iOS 16.2, *)
class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private var currentActivityId: String?
    
    private init() {}
    
    /// Start a Live Activity for the running timer
    func startTimerActivity(timer: ActiveTimer) async {
        print("🚀 [LiveActivityManager] startTimerActivity aufgerufen für: \(timer.projectName)")
        
        #if canImport(ActivityKit)
        print("✅ [LiveActivityManager] ActivityKit verfügbar - starte Live Activity")
        
        // Stop any existing activity first
        await stopTimerActivity()
        
        let attributes = TimerActivityAttributes(
            projectName: timer.projectName,
            activityName: timer.activityName,
            customerName: timer.customerName
        )
        
        let contentState = TimerActivityAttributes.ContentState(
            startDate: timer.startDate
        )
        
        print("📊 [LiveActivityManager] Attributes: \(timer.projectName) - \(timer.activityName)")
        print("📊 [LiveActivityManager] Start Date: \(timer.startDate)")
        
        do {
            let activity = try ActivityKit.Activity.request(
                attributes: attributes,
                content: ActivityContent(state: contentState, staleDate: nil),
                pushType: nil
            )
            
            currentActivityId = activity.id
            print("✅ [LiveActivityManager] Live Activity gestartet: \(activity.id)")
            print("✅ [LiveActivityManager] Activity State: \(activity.activityState)")
        } catch {
            print("❌ [LiveActivityManager] Fehler beim Starten der Live Activity: \(error)")
            print("❌ [LiveActivityManager] Error Details: \(error.localizedDescription)")
        }
        #else
        print("⚠️ [LiveActivityManager] ActivityKit NICHT verfügbar - Live Activity wird nicht gestartet")
        #endif
    }
    
    /// Stop the current Live Activity
    func stopTimerActivity() async {
        #if canImport(ActivityKit)
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
        #else
        print("ℹ️ [LiveActivityManager] ActivityKit nicht verfügbar")
        #endif
    }
    
    /// Update the Live Activity (if needed)
    func updateTimerActivity(timer: ActiveTimer) async {
        #if canImport(ActivityKit)
        guard let activityId = currentActivityId else {
            print("⚠️ [LiveActivityManager] Keine aktive Live Activity zum Aktualisieren")
            return
        }
        
        // Find the activity by ID
        for activity in ActivityKit.Activity<TimerActivityAttributes>.activities {
            if activity.id == activityId {
                let contentState = TimerActivityAttributes.ContentState(
                    startDate: timer.startDate
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
        #else
        print("⚠️ [LiveActivityManager] ActivityKit nicht verfügbar")
        #endif
    }
    
    /// Check if a Live Activity is currently running
    var isActivityRunning: Bool {
        return currentActivityId != nil
    }
}
