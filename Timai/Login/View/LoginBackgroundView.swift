//
//  LoginBackgroundView.swift
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

@available(iOS 13.0, *)
struct LoginBackgroundView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Gradient Hintergrund - adaptive für Light/Dark Mode
            LinearGradient(
                gradient: Gradient(colors: colorScheme == .dark ? [
                    Color(red: 0.1, green: 0.3, blue: 0.6),
                    Color(red: 0.2, green: 0.4, blue: 0.7)
                ] : [
                    Color(red: 0.2, green: 0.5, blue: 0.9),
                    Color(red: 0.4, green: 0.7, blue: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animierte Kreise im Hintergrund
            GeometryReader { geometry in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .offset(x: -100, y: -150)
                    .blur(radius: 10)
                
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 200, height: 200)
                    .offset(x: geometry.size.width - 100, y: 100)
                    .blur(radius: 15)
                
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 250, height: 250)
                    .offset(x: geometry.size.width / 2 - 125, y: geometry.size.height - 200)
                    .blur(radius: 20)
            }
        }
    }
}

