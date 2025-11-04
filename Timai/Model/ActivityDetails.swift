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

struct ActivityDetails: Codable, Identifiable, Hashable {
    let id: Int
    let project: Project?  // Kann null sein bei globalen Activities
    let name: String
    let comment: String?
    let visible: Bool
    let billable: Bool
    let number: String?
    let color: String?
}

