//
//  ActivityDetails.swift
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

struct ActivityDetails: Identifiable, Hashable {
    let id: Int
    let project: Project?  // Kann null sein bei globalen Activities
    let name: String
    let comment: String?
    let visible: Bool
    let billable: Bool
    let number: String?
    let color: String?
}

// MARK: - Codable Implementation
extension ActivityDetails: Codable {
    enum CodingKeys: String, CodingKey {
        case id, project, name, comment, visible, billable, number, color
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        visible = try container.decode(Bool.self, forKey: .visible)
        billable = try container.decode(Bool.self, forKey: .billable)
        number = try container.decodeIfPresent(String.self, forKey: .number)
        color = try container.decodeIfPresent(String.self, forKey: .color)
        
        // Flexibler Project Decoder - kann Int, Project oder null sein
        if let projectObject = try? container.decode(Project.self, forKey: .project) {
            project = projectObject
            print("✅ [ActivityDetails] Project als Objekt dekodiert: \(projectObject.name)")
        } else if let projectId = try? container.decode(Int.self, forKey: .project) {
            // Fallback: Project-ID wurde zurückgegeben statt Objekt
            print("⚠️ [ActivityDetails] Project als ID dekodiert: \(projectId) - setze auf nil")
            project = nil
        } else {
            // Null oder nicht vorhanden
            project = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(project, forKey: .project)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(comment, forKey: .comment)
        try container.encode(visible, forKey: .visible)
        try container.encode(billable, forKey: .billable)
        try container.encodeIfPresent(number, forKey: .number)
        try container.encodeIfPresent(color, forKey: .color)
    }
}

