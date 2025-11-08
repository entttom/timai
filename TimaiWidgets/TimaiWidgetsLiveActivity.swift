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
                
                // Leading: Projekt-Info mit Icon
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 10) {
                        // Pulsierendes Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "timer")
                                .foregroundStyle(.blue)
                                .font(.system(size: 16, weight: .semibold))
                                .symbolEffect(.pulse)
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
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
                
                // Trailing: Timer Display
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(context.state.startDate, style: .timer)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text(NSLocalizedString("timer.running", comment: ""))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                    }
                }
                
                // Bottom: Kunde + Startzeit
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        // Kunde
                        HStack(spacing: 4) {
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 11))
                            Text(context.attributes.customerName)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        // Startzeit
                        HStack(spacing: 4) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 11))
                            Text(context.state.startDate, style: .time)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                
                // ===== COMPACT VIEW =====
            } compactLeading: {
                // Projekt-Kürzel (erste Zeichen)
                HStack(spacing: 2) {
                    Image(systemName: "timer")
                        .font(.system(size: 10))
                        .foregroundStyle(.blue)
                        .symbolEffect(.pulse)
                    
                    Text(projectAbbreviation(context.attributes.projectName))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                        .lineLimit(1)
                }
            } compactTrailing: {
                // Timer
                Text(context.state.startDate, style: .timer)
                    .monospacedDigit()
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                // ===== MINIMAL VIEW =====
            } minimal: {
                // Projekt-Initial
                Text(String(context.attributes.projectName.prefix(1)))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.blue)
            }
            .keylineTint(.blue)
        }
    }
    
    // Helper: Get project abbreviation (max 6 characters)
    private func projectAbbreviation(_ projectName: String) -> String {
        let maxLength = 6
        if projectName.count <= maxLength {
            return projectName
        }
        return String(projectName.prefix(maxLength))
    }
}

/// Lock Screen view for the Live Activity
@available(iOS 17.0, *)
struct TimerLockScreenView: View {
    let context: ActivityViewContext<TimerActivityAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                // Icon mit Gradient-Hintergrund & Pulseffekt
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.25), Color.blue.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "timer")
                        .foregroundStyle(.blue)
                        .font(.system(size: 22, weight: .semibold))
                        .symbolEffect(.pulse)
                }
                
                // Projekt & Activity Info
                VStack(alignment: .leading, spacing: 5) {
                    Text(context.attributes.projectName)
                        .font(.system(size: 17, weight: .bold))
                        .lineLimit(1)
                    
                    Text(context.attributes.activityName)
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 5) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 10))
                        Text(context.attributes.customerName)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(.tertiary)
                }
                
                Spacer()
                
                // Timer Display - Prominent
                VStack(alignment: .trailing, spacing: 6) {
                    Text(context.state.startDate, style: .timer)
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                        
                        Text(NSLocalizedString("timer.running", comment: ""))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                    }
                }
            }
            
            // Trennlinie & Startzeit
            Divider()
                .background(Color.blue.opacity(0.2))
            
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 11))
                    Text(NSLocalizedString("timer.startedAt", comment: ""))
                        .font(.system(size: 12))
                    Text(context.state.startDate, style: .time)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.secondary)
                
                Spacer()
            }
        }
        .padding(16)
        .activityBackgroundTint(Color.blue.opacity(0.08))
        .activitySystemActionForegroundColor(.blue)
    }
}

