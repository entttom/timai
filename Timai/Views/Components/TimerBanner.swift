//
//  TimerBanner.swift
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
import Combine

/// Banner showing active timer at the top of TimesheetView
struct TimerBanner: View {
    let timer: ActiveTimer
    let onStop: () -> Void
    
    @State private var currentTime = Date()
    
    // Timer to update display every second
    let updateTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 12) {
            // Pulsing indicator
            Circle()
                .fill(Color.red)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(Color.red.opacity(0.3), lineWidth: 4)
                        .scaleEffect(1.5)
                )
                .animation(
                    .easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true),
                    value: currentTime
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(timer.projectName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(timer.activityName)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Timer display
            VStack(alignment: .trailing, spacing: 2) {
                Text(timer.startDate, style: .timer)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.white)
                
                Text("timer.running".localized())
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Stop button
            Button(action: onStop) {
                Image(systemName: "stop.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue,
                    Color.blue.opacity(0.8)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 1),
            alignment: .bottom
        )
        .onReceive(updateTimer) { _ in
            currentTime = Date()
        }
    }
}

#Preview {
    TimerBanner(
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
        onStop: {}
    )
}

