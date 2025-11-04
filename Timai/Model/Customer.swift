//
//  Customer.swift
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

struct Customer: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let number: String?
    let comment: String?
    let visible: Bool
    let billable: Bool
    let company: String?
    let country: String
    let currency: String
    let color: String?
}

