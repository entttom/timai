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
import WatchConnectivity

/// Manages communication between Watch and iPhone
@MainActor
class WatchConnectivityService: NSObject, ObservableObject {
    static let shared = WatchConnectivityService()
    
    private var session: WCSession?
    
    // Message type keys
    enum MessageType: String {
        case timerStatus = "timerStatus"
        case startTimer = "startTimer"
        case stopTimer = "stopTimer"
        case requestData = "requestData"
        case dataResponse = "dataResponse"
        case timesheetList = "timesheetList"
        case error = "error"
    }
    
    // Data request types
    enum DataRequestType: String {
        case customers = "customers"
        case projects = "projects"
        case activities = "activities"
        case timesheets = "timesheets"
    }
    
    // Published properties for UI updates
    @Published var currentTimer: ActiveTimer?
    @Published var errorMessage: String?
    
    // Callbacks
    var onTimerStatusUpdate: ((ActiveTimer?) -> Void)?
    var onDataResponse: ((DataRequestType, [[String: Any]]) -> Void)?
    var onTimesheetListUpdate: (([[String: Any]]) -> Void)?
    var onError: ((String) -> Void)?
    
    override init() {
        super.init()
    }
    
    /// Setup WatchConnectivity session
    func setup() {
        guard WCSession.isSupported() else {
            print("⚠️ [WatchConnectivity] WatchConnectivity nicht unterstützt")
            return
        }
        
        session = WCSession.default
        session?.delegate = self
        session?.activate()
        
        print("✅ [WatchConnectivity] Session initialisiert")
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
        
        let message: [String: Any] = [
            "type": MessageType.startTimer.rawValue,
            "projectId": projectId,
            "projectName": projectName,
            "activityId": activityId,
            "activityName": activityName,
            "customerId": customerId,
            "customerName": customerName,
            "description": description ?? NSNull()
        ]
        
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
        
        print("📤 [WatchConnectivity] Start-Timer-Kommando gesendet")
    }
    
    /// Send stop timer command to iPhone
    func stopTimer(description: String? = nil) {
        guard let session = session else {
            sendError("Session nicht verfügbar")
            return
        }
        
        let message: [String: Any] = [
            "type": MessageType.stopTimer.rawValue,
            "description": description ?? NSNull()
        ]
        
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
        
        print("📤 [WatchConnectivity] Stop-Timer-Kommando gesendet")
    }
    
    /// Request data from iPhone
    func requestData(_ type: DataRequestType, customerId: Int? = nil, projectId: Int? = nil) {
        guard let session = session else {
            sendError("Session nicht verfügbar")
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
                if let error = response["error"] as? String {
                    self.sendError(error)
                } else if let requestTypeString = response["requestType"] as? String,
                          let requestType = DataRequestType(rawValue: requestTypeString),
                          let data = response["data"] as? [[String: Any]] {
                    self.onDataResponse?(requestType, data)
                }
            }) { error in
                self.sendError("Fehler beim Anfordern der Daten: \(error.localizedDescription)")
            }
        } else {
            sendError("iPhone nicht erreichbar")
        }
        
        print("📤 [WatchConnectivity] Datenanfrage gesendet: \(type.rawValue)")
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
        errorMessage = message
        onError?(message)
        print("❌ [WatchConnectivity] \(message)")
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("❌ [WatchConnectivity] Session-Aktivierung fehlgeschlagen: \(error.localizedDescription)")
        } else {
            print("✅ [WatchConnectivity] Session aktiviert: \(activationState.rawValue)")
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
            print("⚠️ [WatchConnectivity] Unbekannter Message-Typ")
            return
        }
        
        Task { @MainActor in
            switch type {
            case .timerStatus:
                if let timerData = message["timer"] as? [String: Any] {
                    currentTimer = decodeTimer(timerData)
                    onTimerStatusUpdate?(currentTimer)
                } else {
                    currentTimer = nil
                    onTimerStatusUpdate?(nil)
                }
                
            case .timesheetList:
                if let activities = message["activities"] as? [[String: Any]] {
                    onTimesheetListUpdate?(activities)
                }
                
            case .error:
                if let errorMessage = message["message"] as? String {
                    sendError(errorMessage)
                }
                
            default:
                print("⚠️ [WatchConnectivity] Unbehandelter Message-Typ: \(type)")
            }
        }
    }
}

