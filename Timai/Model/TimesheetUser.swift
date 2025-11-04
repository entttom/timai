//
//  TimesheetUser.swift
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

struct TimesheetUser: Codable, Identifiable {
    let id: Int
    let alias: String?
    let title: String?
    let username: String
}

