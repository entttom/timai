//
//  BiometricAuthService.swift
//  Timai
//
//  Copyright (c) 2025 Dr. Thomas Entner.
//  All rights reserved.
//
//  Licensed under the Business Source License 1.1.
//  Usage is free for non-commercial and personal use.
//  Commercial use requires a commercial license.
//

import LocalAuthentication
import Foundation

/// Service für biometrische Authentifizierung (Face ID/Touch ID) und App Lock
@MainActor
class BiometricAuthService: ObservableObject {
    static let shared = BiometricAuthService()
    
    @Published var isAppLocked = true
    @Published var isAuthenticating = false
    
    private let context = LAContext()
    
    private init() {
        // Prüfe beim Start, ob App Lock aktiviert ist
        isAppLocked = isAppLockEnabled
    }
    
    // MARK: - Settings
    
    /// Gibt an, ob App Lock aktiviert ist
    var isAppLockEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: "appLockEnabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "appLockEnabled")
            if !newValue {
                isAppLocked = false
            } else {
                isAppLocked = true
            }
        }
    }
    
    // MARK: - Biometric Availability
    
    /// Prüft, ob biometrische Authentifizierung verfügbar ist
    var isBiometricAuthAvailable: Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    /// Gibt den Typ der biometrischen Authentifizierung zurück
    var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .opticID
        @unknown default:
            return .none
        }
    }
    
    // MARK: - Authentication
    
    /// Authentifiziert den Benutzer mit Face ID/Touch ID oder Gerätecode
    func authenticateUser() async -> Bool {
        guard isAppLockEnabled else {
            isAppLocked = false
            return true
        }
        
        isAuthenticating = true
        
        let context = LAContext()
        context.localizedCancelTitle = "Abbrechen"
        
        // Erlaube Fallback auf Gerätecode
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            print("❌ [BiometricAuth] Authentifizierung nicht verfügbar: \(error?.localizedDescription ?? "Unbekannter Fehler")")
            isAuthenticating = false
            return false
        }
        
        do {
            let reason = getBiometricAuthReason()
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            
            if success {
                print("✅ [BiometricAuth] Authentifizierung erfolgreich")
                isAppLocked = false
            }
            
            isAuthenticating = false
            return success
        } catch let error as LAError {
            print("❌ [BiometricAuth] Authentifizierung fehlgeschlagen: \(error.localizedDescription)")
            isAuthenticating = false
            
            // Bei bestimmten Fehlern (z.B. Benutzer abgebrochen) nicht automatisch entsperren
            switch error.code {
            case .userCancel, .userFallback, .systemCancel, .appCancel:
                return false
            default:
                return false
            }
        } catch {
            print("❌ [BiometricAuth] Unerwarteter Fehler: \(error)")
            isAuthenticating = false
            return false
        }
    }
    
    /// Sperrt die App
    func lockApp() {
        guard isAppLockEnabled else { return }
        isAppLocked = true
        print("🔒 [BiometricAuth] App gesperrt")
    }
    
    /// Entsperrt die App (nur für manuelle Tests/Entwicklung)
    func unlockApp() {
        isAppLocked = false
        print("🔓 [BiometricAuth] App entsperrt")
    }
    
    // MARK: - Helper
    
    private func getBiometricAuthReason() -> String {
        switch biometricType {
        case .faceID:
            return "Entsperre Timai mit Face ID"
        case .touchID:
            return "Entsperre Timai mit Touch ID"
        case .opticID:
            return "Entsperre Timai mit Optic ID"
        case .none:
            return "Entsperre Timai mit deinem Gerätecode"
        }
    }
}

// MARK: - Biometric Type

enum BiometricType {
    case faceID
    case touchID
    case opticID
    case none
    
    var displayName: String {
        switch self {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return "Gerätecode"
        }
    }
    
    var iconName: String {
        switch self {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        case .none:
            return "lock.fill"
        }
    }
}





