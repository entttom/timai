//
//  CacheSettings.swift
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

struct CacheSettings {
    static var autoSyncEnabled: Bool {
        get {
            // Default to true if not set
            if UserDefaults.standard.object(forKey: "autoSyncEnabled") == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: "autoSyncEnabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "autoSyncEnabled")
        }
    }
    
    static var maxCacheEntries: Int {
        get {
            let value = UserDefaults.standard.integer(forKey: "maxCacheEntries")
            let defaultValue = 200
            if value > 0 {
                // Begrenze auf Maximum 200 (API-Limit)
                return min(value, 200)
            }
            return defaultValue
        }
        set {
            // Begrenze auf Maximum 200 (API-Limit)
            let limitedValue = min(newValue, 200)
            UserDefaults.standard.set(limitedValue, forKey: "maxCacheEntries")
        }
    }
    
    static var cacheRetentionDays: Int {
        get {
            let value = UserDefaults.standard.integer(forKey: "cacheRetentionDays")
            return value > 0 ? value : 30 // Default to 30 days
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "cacheRetentionDays")
        }
    }
    
    // Alias für maxCacheEntries - beide verwenden jetzt die gleiche Einstellung
    static var maxTimesheetEntries: Int {
        get {
            return maxCacheEntries
        }
        set {
            maxCacheEntries = newValue
        }
    }
}


