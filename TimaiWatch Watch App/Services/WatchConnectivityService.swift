//
//  WatchConnectivityService.swift
//  TimaiWatch
//
//  Copyright (c) 2025 Dr. Thomas Entner.
//  All rights reserved.
//
//  Licensed under the Business Source License 1.1.
//  Usage is free for non-commercial and personal use.
//  Commercial use requires a commercial license.
//
import Foundation
import Combine
import WatchConnectivity

/// Manages communication between Watch and iPhone
@MainActor
class WatchConnectivityService: NSObject, ObservableObject {
    static let shared = WatchConnectivityService()
    
    private var session: WCSession?
    private var isSessionActivated = false
    
    // Message type keys
    enum MessageType: String {
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
    enum DataRequestType: String {
        case customers = "customers"
        case projects = "projects"
        case activities = "activities"
        case timesheets = "timesheets"
        case instances = "instances"
    }
    
    // Published properties for UI updates
    @Published var currentTimer: ActiveTimer?
    @Published var errorMessage: String?
    
    // Callbacks - use arrays to support multiple observers
    var onTimerStatusUpdate: ((ActiveTimer?) -> Void)?
    private var onDataResponseCallbacks: [(DataRequestType, [[String: Any]]) -> Void] = []
    var onTimesheetListUpdate: (([[String: Any]]) -> Void)?
    private var onErrorCallbacks: [(String) -> Void] = []
    
    // Public methods to register callbacks
    func addDataResponseObserver(_ callback: @escaping (DataRequestType, [[String: Any]]) -> Void) {
        onDataResponseCallbacks.append(callback)
    }
    
    func addErrorObserver(_ callback: @escaping (String) -> Void) {
        onErrorCallbacks.append(callback)
    }
    
    // Legacy support - setter overwrites all previous callbacks
    var onDataResponse: ((DataRequestType, [[String: Any]]) -> Void)? {
        get { nil }
        set {
            if let callback = newValue {
                onDataResponseCallbacks = [callback]
            } else {
                onDataResponseCallbacks = []
            }
        }
    }
    
    var onError: ((String) -> Void)? {
        get { nil }
        set {
            if let callback = newValue {
                onErrorCallbacks = [callback]
            } else {
                onErrorCallbacks = []
            }
        }
    }
    
    override init() {
        super.init()
    }
    
    /// Setup WatchConnectivity session
    func setup() {
        guard WCSession.isSupported() else {
            return
        }
        
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }
    
    /// Send start timer command to iPhone
    func startTimer(
        projectId: Int,
        projectName: String,
        activityId: Int,
        activityName: String,
        customerId: Int,
        customerName: String,
        description: String?
    ) {
        guard let session = session else {
            sendError("Session nicht verfügbar")
            return
        }
        
        guard isSessionActivated else {
            sendError("Session noch nicht aktiviert - bitte warten")
            return
        }
        
        var message: [String: Any] = [
            "type": MessageType.startTimer.rawValue,
            "projectId": projectId,
            "projectName": projectName,
            "activityId": activityId,
            "activityName": activityName,
            "customerId": customerId,
            "customerName": customerName
        ]
        // Nur description hinzufügen, wenn vorhanden (kein NSNull!)
        if let description = description, !description.isEmpty {
            message["description"] = description
        }
        
        if session.isReachable {
            session.sendMessage(message, replyHandler: { response in
                if let error = response["error"] as? String {
                    self.sendError(error)
                }
            }) { error in
                self.sendError("Fehler beim Senden: \(error.localizedDescription)")
            }
        } else {
            // Use application context for background transfer
            do {
                try session.updateApplicationContext(message)
            } catch {
                sendError("Fehler beim Senden: \(error.localizedDescription)")
            }
        }
    }
    
    /// Send stop timer command to iPhone
    func stopTimer(description: String? = nil) {
        guard let session = session else {
            sendError("Session nicht verfügbar")
            return
        }
        
        guard isSessionActivated else {
            sendError("Session noch nicht aktiviert - bitte warten")
            return
        }
        
        var message: [String: Any] = [
            "type": MessageType.stopTimer.rawValue
        ]
        // Nur description hinzufügen, wenn vorhanden (kein NSNull!)
        if let description = description, !description.isEmpty {
            message["description"] = description
        }
        
        if session.isReachable {
            session.sendMessage(message, replyHandler: { response in
                if let error = response["error"] as? String {
                    self.sendError(error)
                }
            }) { error in
                self.sendError("Fehler beim Senden: \(error.localizedDescription)")
            }
        } else {
            // Use application context for background transfer
            do {
                try session.updateApplicationContext(message)
            } catch {
                sendError("Fehler beim Senden: \(error.localizedDescription)")
            }
        }
    }
    
    /// Create a manual timesheet entry
    func createTimesheet(
        projectId: Int,
        activityId: Int,
        startDate: Date,
        endDate: Date,
        description: String?
    ) {
        guard let session = session else {
            sendError("Session nicht verfügbar")
            return
        }
        
        guard isSessionActivated else {
            sendError("Session noch nicht aktiviert - bitte warten")
            return
        }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var message: [String: Any] = [
            "type": MessageType.createTimesheet.rawValue,
            "projectId": projectId,
            "activityId": activityId,
            "startDate": formatter.string(from: startDate),
            "endDate": formatter.string(from: endDate)
        ]
        
        // Nur description hinzufügen, wenn vorhanden (kein NSNull!)
        if let description = description, !description.isEmpty {
            message["description"] = description
        }
        
        if session.isReachable {
            session.sendMessage(message, replyHandler: { response in
                Task { @MainActor in
                    if let error = response["error"] as? String {
                        self.sendError(error)
                    }
                }
            }) { error in
                self.sendError("Fehler beim Erstellen: \(error.localizedDescription)")
            }
        } else {
            // Use application context for background transfer
            do {
                try session.updateApplicationContext(message)
            } catch {
                sendError("Fehler beim Senden: \(error.localizedDescription)")
            }
        }
    }
    
    /// Switch to a different instance
    func switchInstance(instanceId: String) {
        guard let session = session else {
            sendError("Session nicht verfügbar")
            return
        }
        
        guard isSessionActivated else {
            // Session wird asynchron aktiviert - versuche automatisch erneut
            Task {
                var attempts = 0
                while !isSessionActivated && attempts < 10 {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    attempts += 1
                }
                if isSessionActivated {
                    switchInstance(instanceId: instanceId)
                } else {
                    sendError("Verbindung zum iPhone konnte nicht hergestellt werden")
                }
            }
            return
        }
        
        let message: [String: Any] = [
            "type": MessageType.switchInstance.rawValue,
            "instanceId": instanceId
        ]
        
        if session.isReachable {
            session.sendMessage(message, replyHandler: { response in
                if let error = response["error"] as? String {
                    self.sendError(error)
                }
            }) { error in
                self.sendError("Fehler beim Wechseln der Instanz: \(error.localizedDescription)")
            }
        } else {
            // Use application context for background transfer
            do {
                try session.updateApplicationContext(message)
            } catch {
                sendError("Fehler beim Wechseln der Instanz: \(error.localizedDescription)")
            }
        }
    }
    
    /// Request data from iPhone
    func requestData(_ type: DataRequestType, customerId: Int? = nil, projectId: Int? = nil) {
        guard let session = session else {
            sendError("Session nicht verfügbar")
            return
        }
        
        guard isSessionActivated else {
            // Session wird asynchron aktiviert - versuche automatisch erneut
            // (Dies ist normal beim App-Start und wird automatisch behandelt)
            Task {
                // Warte bis Session aktiviert ist (max. 5 Sekunden)
                var attempts = 0
                while !isSessionActivated && attempts < 10 {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    attempts += 1
                }
                if isSessionActivated {
                    // Retry die Datenanfrage, jetzt sollte die Session aktiviert sein
                    requestData(type, customerId: customerId, projectId: projectId)
                } else {
                    sendError("Verbindung zum iPhone konnte nicht hergestellt werden")
                }
            }
            return
        }
        
        var message: [String: Any] = [
            "type": MessageType.requestData.rawValue,
            "requestType": type.rawValue
        ]
        
        if let customerId = customerId {
            message["customerId"] = customerId
        }
        if let projectId = projectId {
            message["projectId"] = projectId
        }
        
        if session.isReachable {
            session.sendMessage(message, replyHandler: { response in
                Task { @MainActor in
                    if let error = response["error"] as? String {
                        self.sendError(error)
                    } else if let requestTypeString = response["requestType"] as? String,
                              let requestType = DataRequestType(rawValue: requestTypeString),
                              let data = response["data"] as? [[String: Any]] {
                        // Notify all registered observers
                        for callback in self.onDataResponseCallbacks {
                            callback(requestType, data)
                        }
                    } else {
                        self.sendError("Ungültige Antwort vom iPhone")
                    }
                }
            }) { error in
                Task { @MainActor in
                    self.sendError("Fehler beim Anfordern der Daten: \(error.localizedDescription)")
                }
            }
        } else {
            // Use application context for background transfer
            do {
                try session.updateApplicationContext(message)
            } catch {
                Task { @MainActor in
                    self.sendError("Fehler beim Anfordern der Daten: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Private Helpers
    
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
    
    private func sendError(_ message: String) {
        Task { @MainActor in
            self.errorMessage = message
            // Notify all registered error observers
            for callback in self.onErrorCallbacks {
                callback(message)
            }
        }
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
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleMessage(message)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        handleMessage(message)
        replyHandler(["success": true])
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handleMessage(applicationContext)
    }
    
    private func handleMessage(_ message: [String: Any]) {
        guard let typeString = message["type"] as? String,
              let type = MessageType(rawValue: typeString) else {
            return
        }
        
        Task { @MainActor in
            switch type {
            case .timerStatus:
                if let timerData = message["timer"] as? [String: Any] {
                    let timer = decodeTimer(timerData)
                    self.currentTimer = timer
                    self.onTimerStatusUpdate?(timer)
                } else {
                    self.currentTimer = nil
                    self.onTimerStatusUpdate?(nil)
                }
                
            case .dataResponse:
                if let requestTypeString = message["requestType"] as? String,
                   let requestType = DataRequestType(rawValue: requestTypeString),
                   let data = message["data"] as? [[String: Any]] {
                    // Notify all registered observers
                    for callback in self.onDataResponseCallbacks {
                        callback(requestType, data)
                    }
                }
                
            case .switchInstance:
                // Instance switch was successful, refresh data
                // Optionally request updated timer status
                break
                
            case .timesheetList:
                if let activities = message["activities"] as? [[String: Any]] {
                    self.onTimesheetListUpdate?(activities)
                }
                
            case .error:
                if let errorMessage = message["message"] as? String {
                    self.sendError(errorMessage)
                }
                
            default:
                break
            }
        }
    }
}

