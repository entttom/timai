//
//  Timesheet.swift
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

struct Timesheet: Identifiable {
    let id: Int
    let begin: Date
    let end: Date?
    let duration: Int?
    let user: TimesheetUser
    let activity: ActivityDetails
    let project: Project
    let description: String?
    let rate: Double
    let internalRate: Double?
    let fixedRate: Double?
    let hourlyRate: Double?
    let exported: Bool
    let billable: Bool
    let tags: [String]
    
    // Computed properties for compatibility
    var recordId: Int { return id }
    var customerName: String { 
        // Fallback wenn Activity kein Project hat (globale Activity)
        return activity.project?.customer.name ?? project.customer.name 
    }
    var projectName: String { return project.name }
    var task: String { return activity.name }
    var startDateTime: Date { return begin }
    var endDateTime: Date { return end ?? Date() }
    
    // Initializer for creating new instances
    init(id: Int, begin: Date, end: Date?, duration: Int?, user: TimesheetUser, activity: ActivityDetails, project: Project, description: String?, rate: Double, internalRate: Double?, fixedRate: Double?, hourlyRate: Double?, exported: Bool, billable: Bool, tags: [String]) {
        self.id = id
        self.begin = begin
        self.end = end
        self.duration = duration
        self.user = user
        self.activity = activity
        self.project = project
        self.description = description
        self.rate = rate
        self.internalRate = internalRate
        self.fixedRate = fixedRate
        self.hourlyRate = hourlyRate
        self.exported = exported
        self.billable = billable
        self.tags = tags
    }
}

// MARK: - Codable Implementation
extension Timesheet: Codable {
    enum CodingKeys: String, CodingKey {
        case id, begin, end, duration, user, activity, project, description
        case rate, internalRate, fixedRate, hourlyRate, exported, billable, tags
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        begin = try container.decode(Date.self, forKey: .begin)
        end = try container.decodeIfPresent(Date.self, forKey: .end)
        duration = try container.decodeIfPresent(Int.self, forKey: .duration)
        
        // Flexibler User Decoder - kann sowohl Int als auch TimesheetUser sein
        if let userObject = try? container.decode(TimesheetUser.self, forKey: .user) {
            user = userObject
        } else if let userId = try? container.decode(Int.self, forKey: .user) {
            // Fallback: Erstelle einen minimalen User mit nur der ID
            user = TimesheetUser(id: userId, alias: nil, title: nil, username: "User \(userId)", roles: nil)
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .user,
                in: container,
                debugDescription: "User muss entweder Int oder TimesheetUser sein"
            )
        }
        
        // Flexibler Activity Decoder - kann sowohl Int als auch ActivityDetails sein
        if let activityObject = try? container.decode(ActivityDetails.self, forKey: .activity) {
            activity = activityObject
            print("✅ [Timesheet] Activity als Objekt dekodiert: \(activityObject.name)")
        } else if let activityId = try? container.decode(Int.self, forKey: .activity) {
            // Fallback: Erstelle eine minimale Activity mit nur der ID
            print("⚠️ [Timesheet] Activity als ID dekodiert: \(activityId) - verwende Fallback")
            activity = ActivityDetails(id: activityId, project: nil, name: "Activity \(activityId)", comment: nil, visible: true, billable: true, number: nil, color: nil)
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .activity,
                in: container,
                debugDescription: "Activity muss entweder Int oder ActivityDetails sein"
            )
        }
        
        // Flexibler Project Decoder - kann sowohl Int als auch Project sein
        if let projectObject = try? container.decode(Project.self, forKey: .project) {
            project = projectObject
            print("✅ [Timesheet] Project als Objekt dekodiert: \(projectObject.name)")
        } else if let projectId = try? container.decode(Int.self, forKey: .project) {
            // Fallback: Erstelle ein minimales Project mit nur der ID
            print("⚠️ [Timesheet] Project als ID dekodiert: \(projectId) - verwende Fallback")
            let minimalCustomer = Customer(id: 0, name: "", number: nil, comment: nil, visible: true, billable: true, company: nil, country: "", currency: "", color: nil)
            project = Project(id: projectId, customer: minimalCustomer, name: "Project \(projectId)", orderNumber: nil, start: nil, end: nil, visible: true, billable: true, color: nil, budget: nil, timeBudget: nil, budgetType: nil)
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .project,
                in: container,
                debugDescription: "Project muss entweder Int oder Project sein"
            )
        }
        description = try container.decodeIfPresent(String.self, forKey: .description)
        rate = try container.decode(Double.self, forKey: .rate)
        internalRate = try container.decodeIfPresent(Double.self, forKey: .internalRate)
        fixedRate = try container.decodeIfPresent(Double.self, forKey: .fixedRate)
        hourlyRate = try container.decodeIfPresent(Double.self, forKey: .hourlyRate)
        exported = try container.decode(Bool.self, forKey: .exported)
        billable = try container.decode(Bool.self, forKey: .billable)
        tags = try container.decode([String].self, forKey: .tags)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(begin, forKey: .begin)
        try container.encodeIfPresent(end, forKey: .end)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encode(user, forKey: .user)
        try container.encode(activity, forKey: .activity)
        try container.encode(project, forKey: .project)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(rate, forKey: .rate)
        try container.encodeIfPresent(internalRate, forKey: .internalRate)
        try container.encodeIfPresent(fixedRate, forKey: .fixedRate)
        try container.encodeIfPresent(hourlyRate, forKey: .hourlyRate)
        try container.encode(exported, forKey: .exported)
        try container.encode(billable, forKey: .billable)
        try container.encode(tags, forKey: .tags)
    }
}

