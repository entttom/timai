//
//  User.swift
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
import KeychainAccess

struct User: Equatable {
    let apiEndpoint: URL
    var userDetails: TimesheetUser?  // Details über den aktuellen User inkl. Rollen
    var instanceId: UUID?  // Optional: ID der zugehörigen Instanz
    
    var apiToken: String? {
        get {
            let keychain = Keychain(service: Bundle.main.bundleIdentifier!)
            
            // If we have an instance ID, use instance-specific token
            if let instanceId = instanceId {
                let instanceKey = "apiToken_\(instanceId.uuidString)"
                if let token = try? keychain.get(instanceKey) {
                    return token
                }
            }
            
            // Fallback to generic token (for backward compatibility)
            if let token = try? keychain.get("apiToken") {
                return token
            }
            
            return nil
        }
        set {
            guard let token = newValue else { return }
            let keychain = Keychain(service: Bundle.main.bundleIdentifier!)
            
            // If we have an instance ID, save to instance-specific key
            if let instanceId = instanceId {
                let instanceKey = "apiToken_\(instanceId.uuidString)"
                try? keychain.set(token, key: instanceKey)
            } else {
                // Fallback to generic key
                try? keychain.set(token, key: "apiToken")
            }
        }
    }

    init(apiEndpoint: URL, apiToken: String?, userDetails: TimesheetUser? = nil, instanceId: UUID? = nil) {
        self.apiEndpoint = apiEndpoint
        self.instanceId = instanceId
        self.userDetails = userDetails
        
        // Set token if provided
        if let token = apiToken {
            var tempUser = self
            tempUser.apiToken = token
        }
    }
    
    // Hilfsfunktion: Prüft ob User eine bestimmte Rolle hat
    func hasRole(_ role: String) -> Bool {
        return userDetails?.hasRole(role) ?? false
    }
    
    // Hilfsfunktion: Prüft ob User eine der angegebenen Rollen hat
    func hasAnyRole(_ roles: [String]) -> Bool {
        return userDetails?.hasAnyRole(roles) ?? false
    }
}
