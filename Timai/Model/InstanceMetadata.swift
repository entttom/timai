//
//  InstanceMetadata.swift
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

struct InstanceMetadata: Codable {
    let version: String
    let versionId: Int?
    let copyright: String
    
    // Legacy fields (alte Kimai Versionen)
    let candidate: String?
    let semver: String?
    let name: String?
    
    var displayName: String {
        return name ?? "Kimai"
    }
}
