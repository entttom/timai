//
//  ProjectCollection.swift
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

// Für die Projects-Liste API (mit customer ID statt Objekt)
struct ProjectCollection: Codable {
    let id: Int
    let customer: Int  // Nur die ID
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
    
    // Konvertiere zu Project mit Customer-Objekt
    func toProject(customer: Customer) -> Project {
        return Project(
            id: id,
            customer: customer,
            name: name,
            orderNumber: orderNumber,
            start: start,
            end: end,
            visible: visible,
            billable: billable,
            color: color,
            budget: budget,
            timeBudget: timeBudget,
            budgetType: budgetType
        )
    }
}

