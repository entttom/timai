//
//  Credits.swift
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

struct CreditProject {
    let name: String
    let author: String
    let website: URL?
}

struct Credits {
    static let oss = [
        CreditProject(name: "KeychainAccess", author: "Kishikawa Katsumi", website: URL(string: "https://github.com/kishikawakatsumi/KeychainAccess"))
    ]

    static let graphics = [
        CreditProject(name: "SF Symbols", author: "Apple Inc.", website: URL(string: "https://developer.apple.com/sf-symbols/")),
        CreditProject(name: "App Icon Design", author: "Timai Contributors", website: nil)
    ]
}
