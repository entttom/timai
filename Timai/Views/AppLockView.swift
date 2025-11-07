//
//  AppLockView.swift
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

struct AppLockView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var biometricService = BiometricAuthService.shared
    @State private var isAuthenticating = false
    
    var body: some View {
        ZStack {
            // Background
            Color.timaiHighlight
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App Logo
                Text("Timai")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
                
                // Lock Icon
                VStack(spacing: 16) {
                    Image(systemName: biometricService.biometricType.iconName)
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.bottom, 8)
                    
                    Text("appLock.title".localized())
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(getUnlockMessage())
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Unlock Button
                Button(action: {
                    authenticate()
                }) {
                    HStack(spacing: 12) {
                        if isAuthenticating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .timaiHighlight))
                        } else {
                            Image(systemName: biometricService.biometricType.iconName)
                                .font(.system(size: 20))
                            Text("appLock.button.unlock".localized())
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        colorScheme == .dark 
                            ? Color(white: 0.95)
                            : Color.white
                    )
                    .foregroundColor(.timaiHighlight)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 40)
                .disabled(isAuthenticating)
                
                Spacer()
                    .frame(height: 60)
            }
        }
        .onAppear {
            // Automatisch authentifizieren beim Erscheinen
            authenticate()
        }
    }
    
    private func authenticate() {
        isAuthenticating = true
        
        Task {
            let success = await biometricService.authenticateUser()
            isAuthenticating = false
            
            // Kein Fehler-Alert nötig - Benutzer kann einfach nochmal auf "Entsperren" drücken
            // wenn die Authentifizierung fehlschlägt oder abgebrochen wurde
        }
    }
    
    private func getUnlockMessage() -> String {
        switch biometricService.biometricType {
        case .faceID:
            return "appLock.message.faceID".localized()
        case .touchID:
            return "appLock.message.touchID".localized()
        case .opticID:
            return "appLock.message.opticID".localized()
        case .none:
            return "appLock.message.passcode".localized()
        }
    }
}

#Preview {
    AppLockView()
}

