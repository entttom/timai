//
//  Tag.swift
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

/// Represents a tag from the Kimai API
struct Tag: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let color: String?
    let colorSafe: String?
    let visible: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case color
        case colorSafe = "color-safe"
        case visible
    }
}

