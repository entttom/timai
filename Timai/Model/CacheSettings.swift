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
            return value > 0 ? value : 100 // Default to 100
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "maxCacheEntries")
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
}


