//
//  Project.swift
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

struct Project: Codable, Identifiable, Hashable {
    let id: Int
    let customer: Customer
    let name: String
    let orderNumber: String?
    let start: Date?
    let end: Date?
    let visible: Bool
    let billable: Bool
    let color: String?
    let budget: Float?
    let timeBudget: Int?
    let budgetType: String?
}

