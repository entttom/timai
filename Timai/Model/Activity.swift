//
//  Activity.swift
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

struct Activity: Identifiable {
    var id: Int { recordId }
    
    let recordId: Int
    let description: String?
    let tags: [String]?
    let customerName: String
    let customerId: Int
    let projectName: String
    let projectId: Int
    let task: String
    let activityId: Int
    let startDateTime: Date
    let endDateTime: Date

    enum CodingKeys: String, CodingKey {
        case recordId = "timeEntryID"
        case description
        case tags
        case customerName
        case customerId
        case projectName
        case projectId
        case task = "activityName"
        case activityId
        case startDateTime = "start"
        case endDateTime = "end"
    }
}

extension Activity: Decodable {

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        recordId = Int(try container.decode(String.self, forKey: .recordId))!
        description = try container.decodeIfPresent(String.self, forKey: .description)
        tags = try container.decodeIfPresent([String].self, forKey: .tags)
        customerName = try container.decode(String.self, forKey: .customerName)
        customerId = try container.decode(Int.self, forKey: .customerId)
        projectName = try container.decode(String.self, forKey: .projectName)
        projectId = try container.decode(Int.self, forKey: .projectId)
        task = try container.decode(String.self, forKey: .task)
        activityId = try container.decode(Int.self, forKey: .activityId)
        startDateTime = Date(timeIntervalSince1970: Double(try container.decode(String.self, forKey: .startDateTime))!)
        endDateTime = Date(timeIntervalSince1970: Double(try container.decode(String.self, forKey: .endDateTime))!)
    }

}
