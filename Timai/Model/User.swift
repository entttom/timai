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
    
    var apiToken: String? {
        get {
            let keychain = Keychain(service: Bundle.main.bundleIdentifier!)
            if let token = try? keychain.get("apiToken") ?? nil {
                return token
            } else {
                return nil
            }
        }
        set {
            guard let token = newValue else { return }
            try? Keychain(service: Bundle.main.bundleIdentifier!).set(token, key: "apiToken")
        }
    }

    init(apiEndpoint: URL, apiToken: String?, userDetails: TimesheetUser? = nil) {
        self.apiEndpoint = apiEndpoint
        self.apiToken = apiToken
        self.userDetails = userDetails
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
