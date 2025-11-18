//
//  TimaiWidgetsLiveActivity.swift
//  TimaiWidgets
//
//  Copyright (c) 2025 Dr. Thomas Entner.
//  All rights reserved.
//
//  Licensed under the Business Source License 1.1.
//  Usage is free for non-commercial and personal use.
//  Commercial use requires a commercial license.
//
import SwiftUI
import WidgetKit

#if os(iOS)
import ActivityKit

/// Live Activity Widget for running timer
@available(iOS 17.0, *)
struct TimaiWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            // Lock Screen / Banner UI
            TimerLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // ===== EXPANDED VIEW =====
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 12) {
                        Image(systemName: "timer")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.blue)
                            .symbolEffect(.pulse)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.attributes.projectName)
                                .font(.system(size: 15, weight: .semibold))
                                .lineLimit(1)
                            
                            Text(context.attributes.activityName)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.startDate, style: .timer)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.blue)
                }
                
                // ===== COMPACT VIEW =====
            } compactLeading: {
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.system(size: 10))
                        .foregroundStyle(.blue)
                        .symbolEffect(.pulse)
                    
                    Text(context.attributes.projectName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.blue)
                        .lineLimit(1)
                }
            } compactTrailing: {
                Text(context.state.startDate, style: .timer)
                    .monospacedDigit()
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.blue)
                
                // ===== MINIMAL VIEW =====
            } minimal: {
                Image(systemName: "timer")
                    .foregroundStyle(.blue)
            }
            .keylineTint(.blue)
        }
    }
}

/// Lock Screen view for the Live Activity
@available(iOS 17.0, *)
struct TimerLockScreenView: View {
    let context: ActivityViewContext<TimerActivityAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                // Icon mit Pulseffekt
                Image(systemName: "timer")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.blue)
                    .symbolEffect(.pulse)
                
                // Projekt & Activity Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.attributes.projectName)
                        .font(.system(size: 17, weight: .bold))
                        .lineLimit(1)
                    
                    Text(context.attributes.activityName)
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Timer Display
                Text(context.state.startDate, style: .timer)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.blue)
            }
        }
        .padding(16)
        .activityBackgroundTint(Color.blue.opacity(0.08))
        .activitySystemActionForegroundColor(.blue)
    }
}
#endif
