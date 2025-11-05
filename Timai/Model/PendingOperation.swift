//
//  PendingOperation.swift
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

struct PendingOperationItem: Identifiable, Codable {
    let id: String
    var operation: PendingOperation // Changed to var to allow updating IDs
    let timestamp: Date
    var status: OperationStatus
    var retryCount: Int
    var lastError: String?
    var tempIdHash: Int? // Store the hash for CREATE operations
    
    enum OperationStatus: String, Codable {
        case pending
        case syncing
        case failed
        case completed
    }
    
    init(id: String = UUID().uuidString, operation: PendingOperation, timestamp: Date = Date(), status: OperationStatus = .pending, retryCount: Int = 0, lastError: String? = nil, tempIdHash: Int? = nil) {
        self.id = id
        self.operation = operation
        self.timestamp = timestamp
        self.status = status
        self.retryCount = retryCount
        self.lastError = lastError
        self.tempIdHash = tempIdHash
    }
}

enum PendingOperation: Codable {
    case createTimesheet(form: TimesheetEditForm, tempId: String)
    case updateTimesheet(id: Int, form: TimesheetEditForm)
    case deleteTimesheet(id: Int)
    
    var description: String {
        switch self {
        case .createTimesheet:
            return "Timesheet erstellen"
        case .updateTimesheet:
            return "Timesheet aktualisieren"
        case .deleteTimesheet:
            return "Timesheet löschen"
        }
    }
    
    var tempId: String? {
        switch self {
        case .createTimesheet(_, let tempId):
            return tempId
        default:
            return nil
        }
    }
    
    var projectId: Int? {
        switch self {
        case .createTimesheet(let form, _):
            return form.project
        case .updateTimesheet(_, let form):
            return form.project
        default:
            return nil
        }
    }
    
    var activityId: Int? {
        switch self {
        case .createTimesheet(let form, _):
            return form.activity
        case .updateTimesheet(_, let form):
            return form.activity
        default:
            return nil
        }
    }
}


