//
//  TimerStopDialog.swift
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
#if os(macOS)
import AppKit
#endif

/// Dialog for stopping timer and adding description
struct TimerStopDialog: View {
    let timer: ActiveTimer
    let onStop: (String?) -> Void
    let onCancel: () -> Void
    let onSaveDescription: (String?) -> Void
    
    @State private var descriptionText = ""
    @FocusState private var isDescriptionFocused: Bool
    
    private var cancelButtonBackgroundColor: Color {
        #if os(iOS)
        return Color(.systemGray5)
        #else
        return Color(white: 0.9)
        #endif
    }
    
    private var dialogBackgroundColor: Color {
        #if os(iOS)
        return Color(.systemBackground)
        #else
        return Color(NSColor.windowBackgroundColor)
        #endif
    }
    
    private var initialDescription: String {
        timer.description ?? ""
    }
    
    private var hasDescriptionChanges: Bool {
        descriptionText != initialDescription
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "clock.badge.checkmark.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                Text("timer.stop.title".localized())
                    .font(.system(size: 20, weight: .bold))
                
                Text(timer.startDate, style: .timer)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.blue)
            }
            
            // Project info
            VStack(spacing: 4) {
                Text(timer.projectName)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(timer.activityName)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Description field
            VStack(alignment: .leading, spacing: 8) {
                Text("timer.stop.description.label".localized())
                    .font(.system(size: 14, weight: .medium))
                
                TextField("timer.stop.description.placeholder".localized(), text: $descriptionText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
                    .focused($isDescriptionFocused)
            }
            
            // Buttons
            HStack(spacing: 12) {
                Button(action: onCancel) {
                    Text("timesheetEdit.button.cancel".localized())
                        .font(.system(size: 16, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(cancelButtonBackgroundColor)
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
                
                if hasDescriptionChanges {
                    Button(action: {
                        onSaveDescription(descriptionText.isEmpty ? nil : descriptionText)
                    }) {
                        Text("timesheetEdit.button.save".localized())
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .cornerRadius(10)
                    }
                }
                
                Button(action: {
                    onStop(descriptionText.isEmpty ? timer.description : descriptionText)
                }) {
                    Text("timer.stop.button".localized())
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding(24)
        .background(dialogBackgroundColor)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        .padding(40)
        .onAppear {
            // Pre-fill description if exists
            if let existingDesc = timer.description {
                descriptionText = existingDesc
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
        
        TimerStopDialog(
            timer: ActiveTimer(
                timesheetId: 123,
                projectId: 1,
                projectName: "Website Redesign",
                activityId: 2,
                activityName: "Development",
                customerId: 3,
                customerName: "ACME Corp",
                startDate: Date().addingTimeInterval(-3665),
                description: nil
            ),
            onStop: { _ in },
            onCancel: {},
            onSaveDescription: { _ in }
        )
    }
}

