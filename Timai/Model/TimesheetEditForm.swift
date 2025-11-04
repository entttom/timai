//
//  TimesheetEditForm.swift
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

struct TimesheetEditForm: Codable {
    let project: Int
    let activity: Int
    let begin: String?
    let end: String?
    let description: String?
    let tags: String?
    let fixedRate: Double?
    let hourlyRate: Double?
    let user: Int?
    let exported: Bool?
    let billable: Bool?
}

