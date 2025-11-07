//
//  TimesheetUser.swift
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

struct TimesheetUser: Codable, Identifiable, Equatable {
    let id: Int
    let alias: String?
    let title: String?
    let username: String
    let roles: [String]?  // Optional, nur bei /api/users/me verfügbar
    
    // Hilfsfunktion um Berechtigungen zu prüfen
    func hasRole(_ role: String) -> Bool {
        return roles?.contains(role) ?? false
    }
    
    // Prüft ob User eine der angegebenen Rollen hat
    func hasAnyRole(_ checkRoles: [String]) -> Bool {
        guard let userRoles = roles else { return false }
        return !Set(userRoles).isDisjoint(with: Set(checkRoles))
    }
}

