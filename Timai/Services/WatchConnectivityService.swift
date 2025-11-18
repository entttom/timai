//
//  WatchConnectivityService.swift
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
import WatchConnectivity

#if os(iOS)

/// Manages communication between iPhone and Apple Watch
@MainActor
class WatchConnectivityService: NSObject, ObservableObject {
    static let shared = WatchConnectivityService()
    
    private var session: WCSession?
    private var isSessionActivated = false
    private let networkService = NetworkService.shared
    private let instanceManager = InstanceManager.shared
    private var currentUser: User?
    
    // Message type keys
    private enum MessageType: String {
        case timerStatus = "timerStatus"
        case startTimer = "startTimer"
        case stopTimer = "stopTimer"
        case requestData = "requestData"
        case dataResponse = "dataResponse"
        case timesheetList = "timesheetList"
        case switchInstance = "switchInstance"
        case createTimesheet = "createTimesheet"
        case error = "error"
    }
    
    // Data request types
    private enum DataRequestType: String {
        case customers = "customers"
        case projects = "projects"
        case activities = "activities"
        case timesheets = "timesheets"
        case instances = "instances"
    }
    
    override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    /// Setup WatchConnectivity session
    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            return
        }
        
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }
    
    /// Set current user for data requests
    func setUser(_ user: User) {
        self.currentUser = user
    }
    
    /// Send timer status to Watch
    func sendTimerStatus(_ timer: ActiveTimer?) {
        guard let session = session else {
            return
        }
        
        guard isSessionActivated else {
            return
        }
        
        var message: [String: Any] = [
            "type": MessageType.timerStatus.rawValue
        ]
        if let timer = timer {
            message["timer"] = encodeTimer(timer)
        }
        
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { _ in }
        } else {
            // Use application context for background transfer
            do {
                try session.updateApplicationContext(message)
            } catch {
                // Ignore errors
            }
        }
    }
    
    /// Send timesheet list to Watch
    func sendTimesheetList(_ activities: [Activity]) {
        guard let session = session else {
            return
        }
        
        guard isSessionActivated else {
            return
        }
        
        let compactActivities = activities.prefix(20).map { activity -> [String: Any] in
            var dict: [String: Any] = [
                "id": activity.recordId,
                "projectName": activity.projectName,
                "activityName": activity.task,
                "customerName": activity.customerName,
                "startDateTime": activity.startDateTime.timeIntervalSince1970,
                "endDateTime": activity.endDateTime.timeIntervalSince1970,
                "tags": activity.tags ?? []
            ]
            // Nur description hinzufügen, wenn vorhanden (kein NSNull!)
            if let description = activity.description, !description.isEmpty {
                dict["description"] = description
            }
            return dict
        }
        
        let message: [String: Any] = [
            "type": MessageType.timesheetList.rawValue,
            "activities": compactActivities
        ]
        
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { _ in }
        } else {
            // Use application context for background transfer
            do {
                try session.updateApplicationContext(message)
            } catch {
                // Ignore errors
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func encodeTimer(_ timer: ActiveTimer) -> [String: Any] {
        var dict: [String: Any] = [
            "projectId": timer.projectId,
            "projectName": timer.projectName,
            "activityId": timer.activityId,
            "activityName": timer.activityName,
            "customerId": timer.customerId,
            "customerName": timer.customerName,
            "startDate": timer.startDate.timeIntervalSince1970
        ]
        // Nur optionale Werte hinzufügen, wenn sie vorhanden sind (kein NSNull!)
        if let timesheetId = timer.timesheetId {
            dict["timesheetId"] = timesheetId
        }
        if let description = timer.description, !description.isEmpty {
            dict["description"] = description
        }
        return dict
    }
    
    private func decodeTimer(_ data: [String: Any]) -> ActiveTimer? {
        guard let projectId = data["projectId"] as? Int,
              let projectName = data["projectName"] as? String,
              let activityId = data["activityId"] as? Int,
              let activityName = data["activityName"] as? String,
              let customerId = data["customerId"] as? Int,
              let customerName = data["customerName"] as? String,
              let startDateTimestamp = data["startDate"] as? TimeInterval else {
            return nil
        }
        
        let timesheetId = data["timesheetId"] as? Int
        let description = data["description"] as? String
        
        return ActiveTimer(
            timesheetId: timesheetId,
            projectId: projectId,
            projectName: projectName,
            activityId: activityId,
            activityName: activityName,
            customerId: customerId,
            customerName: customerName,
            startDate: Date(timeIntervalSince1970: startDateTimestamp),
            description: description
        )
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if let error = error {
                isSessionActivated = false
            } else {
                isSessionActivated = (activationState == .activated)
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        // Session became inactive
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate session
        session.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleMessage(message)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        handleMessage(message, replyHandler: replyHandler)
    }
    
    private func handleMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)? = nil) {
        guard let typeString = message["type"] as? String,
              let type = MessageType(rawValue: typeString) else {
            replyHandler?(["error": "Unknown message type"])
            return
        }
        
        Task { @MainActor in
            switch type {
            case .startTimer:
                await handleStartTimer(message)
                replyHandler?(["success": true])
                
            case .stopTimer:
                await handleStopTimer(message)
                replyHandler?(["success": true])
                
            case .requestData:
                let response = await handleDataRequest(message)
                replyHandler?(response)
                
            case .switchInstance:
                await handleSwitchInstance(message)
                replyHandler?(["success": true])
                
            case .createTimesheet:
                let success = await handleCreateTimesheet(message)
                replyHandler?(["success": success])
                
            default:
                replyHandler?(["error": "Unhandled message type"])
            }
        }
    }
    
    private func handleStartTimer(_ message: [String: Any]) async {
        guard let user = currentUser,
              let projectId = message["projectId"] as? Int,
              let projectName = message["projectName"] as? String,
              let activityId = message["activityId"] as? Int,
              let activityName = message["activityName"] as? String,
              let customerId = message["customerId"] as? Int,
              let customerName = message["customerName"] as? String else {
            return
        }
        
        let description = message["description"] as? String
        
        do {
            try await TimerManager.shared.startTimer(
                projectId: projectId,
                projectName: projectName,
                activityId: activityId,
                activityName: activityName,
                customerId: customerId,
                customerName: customerName,
                description: description,
                user: user
            )
        } catch {
            sendErrorToWatch("Failed to start timer: \(error.localizedDescription)")
        }
    }
    
    private func handleStopTimer(_ message: [String: Any]) async {
        guard let user = currentUser else {
            return
        }
        
        let finalDescription = message["description"] as? String
        
        do {
            try await TimerManager.shared.stopTimer(user: user, finalDescription: finalDescription)
        } catch {
            sendErrorToWatch("Failed to stop timer: \(error.localizedDescription)")
        }
    }
    
    private func handleCreateTimesheet(_ message: [String: Any]) async -> Bool {
        guard let user = currentUser,
              let projectId = message["projectId"] as? Int,
              let activityId = message["activityId"] as? Int,
              let startDateString = message["startDate"] as? String,
              let endDateString = message["endDate"] as? String else {
            sendErrorToWatch("Invalid timesheet data")
            return false
        }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let startDate = formatter.date(from: startDateString),
              let endDate = formatter.date(from: endDateString) else {
            sendErrorToWatch("Invalid date format")
            return false
        }
        
        let description = message["description"] as? String
        
        let form = TimesheetEditForm(
            project: projectId,
            activity: activityId,
            begin: startDate.ISO8601Format(),
            end: endDate.ISO8601Format(),
            description: description,
            tags: nil,
            fixedRate: nil,
            hourlyRate: nil,
            user: nil,
            exported: nil,
            billable: true
        )
        
        do {
            _ = try await networkService.createTimesheet(form: form, user: user)
            return true
        } catch {
            sendErrorToWatch("Failed to create timesheet: \(error.localizedDescription)")
            return false
        }
    }
    
    private func handleSwitchInstance(_ message: [String: Any]) async {
        guard let instanceIdString = message["instanceId"] as? String,
              let instanceId = UUID(uuidString: instanceIdString),
              let instance = instanceManager.getInstance(id: instanceId) else {
            sendErrorToWatch("Invalid instance ID")
            return
        }
        
        instanceManager.switchToInstance(instance)
        
        // Update current user after instance switch
        if let token = instance.apiToken {
            let newUser = User(apiEndpoint: instance.apiEndpoint, apiToken: token)
            setUser(newUser)
            
            // Sync timer state with new instance
            Task { @MainActor in
                await TimerManager.shared.syncActiveTimerFromServer(user: newUser)
            }
        }
    }
    
    private func handleDataRequest(_ message: [String: Any]) async -> [String: Any] {
        let requestTypeString = message["requestType"] as? String
        let requestType = DataRequestType(rawValue: requestTypeString ?? "")
        
        // Instances don't need a user
        if requestType == .instances {
            // Continue without user check
        } else {
            guard let user = currentUser else {
                return ["error": "No user available"]
            }
        }
        
        guard let requestType = requestType else {
            return ["error": "Invalid request"]
        }
        
        do {
            switch requestType {
            case .instances:
                let instances = instanceManager.instances
                let compactInstances = instances.map { instance -> [String: Any] in
                    [
                        "id": instance.id.uuidString,
                        "name": instance.name,
                        "apiEndpoint": instance.apiEndpoint.absoluteString,
                        "isActive": instance.isActive
                    ]
                }
                return [
                    "type": MessageType.dataResponse.rawValue,
                    "requestType": requestTypeString ?? "",
                    "data": compactInstances
                ]
                
            case .customers:
                guard let user = currentUser else {
                    return ["error": "No user available"]
                }
                let customers = try await networkService.getCustomers(user: user)
                let compactCustomers = customers.map { ["id": $0.id, "name": $0.name] }
                return [
                    "type": MessageType.dataResponse.rawValue,
                    "requestType": requestTypeString,
                    "data": compactCustomers
                ]
                
            case .projects:
                guard let user = currentUser else {
                    return ["error": "No user available"]
                }
                guard let customerId = message["customerId"] as? Int else {
                    return ["error": "Missing customerId"]
                }
                let customer = Customer(id: customerId, name: "", number: nil, comment: nil, visible: true, billable: true, company: nil, country: "", currency: "", color: nil)
                let projects = try await networkService.getProjects(customer: customer, user: user)
                let compactProjects = projects.map { [
                    "id": $0.id,
                    "name": $0.name,
                    "customerId": $0.customer.id
                ] }
                return [
                    "type": MessageType.dataResponse.rawValue,
                    "requestType": requestTypeString,
                    "data": compactProjects
                ]
                
            case .activities:
                guard let user = currentUser else {
                    return ["error": "No user available"]
                }
                guard let projectId = message["projectId"] as? Int else {
                    return ["error": "Missing projectId"]
                }
                let activities = try await networkService.getActivities(projectId: projectId, user: user)
                let compactActivities = activities.map { [
                    "id": $0.id,
                    "name": $0.name
                ] }
                return [
                    "type": MessageType.dataResponse.rawValue,
                    "requestType": requestTypeString,
                    "data": compactActivities
                ]
                
            case .timesheets:
                guard let user = currentUser else {
                    return ["error": "No user available"]
                }
                let activities = try await networkService.getTimesheetFor(user)
                let compactActivities = activities.prefix(20).map { activity -> [String: Any] in
                    var dict: [String: Any] = [
                        "id": activity.recordId,
                        "projectName": activity.projectName,
                        "activityName": activity.task,
                        "customerName": activity.customerName,
                        "startDateTime": activity.startDateTime.timeIntervalSince1970,
                        "endDateTime": activity.endDateTime.timeIntervalSince1970,
                        "tags": activity.tags ?? []
                    ]
                    // Nur description hinzufügen, wenn vorhanden (kein NSNull!)
                    if let description = activity.description, !description.isEmpty {
                        dict["description"] = description
                    }
                    return dict
                }
                return [
                    "type": MessageType.dataResponse.rawValue,
                    "requestType": requestTypeString,
                    "data": compactActivities
                ]
            }
        } catch {
            return ["error": error.localizedDescription]
        }
    }
    
    private func sendErrorToWatch(_ errorMessage: String) {
        guard let session = session, isSessionActivated else { return }
        
        if !session.isReachable {
            // Use application context if not reachable
            let message: [String: Any] = [
                "type": MessageType.error.rawValue,
                "message": errorMessage
            ]
            do {
                try session.updateApplicationContext(message)
            } catch {
                // Ignore errors
            }
            return
        }
        
        let message: [String: Any] = [
            "type": MessageType.error.rawValue,
            "message": errorMessage
        ]
        
        session.sendMessage(message, replyHandler: nil) { _ in }
    }
}

#endif

