//
//  NetworkMonitor.swift
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
import Network
import Combine

@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published private(set) var isConnected: Bool = true
    @Published private(set) var connectionType: ConnectionType = .unknown
    
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.timai.networkmonitor")
    
    enum ConnectionType {
        case wifi
        case cellular
        case wiredEthernet
        case unknown
        case none
    }
    
    private init() {
        monitor = NWPathMonitor()
        
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.updateConnectionStatus(path: path)
            }
        }
        
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
    
    private func updateConnectionStatus(path: NWPath) {
        let wasConnected = isConnected
        isConnected = path.status == .satisfied
        
        // Determine connection type
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wiredEthernet
        } else if path.status == .satisfied {
            connectionType = .unknown
        } else {
            connectionType = .none
        }
        
        // Log status changes
        if wasConnected != isConnected {
            if isConnected {
                NotificationCenter.default.post(name: .networkConnectionRestored, object: nil)
            } else {
                NotificationCenter.default.post(name: .networkConnectionLost, object: nil)
            }
        }
    }
    
    /// Force check current network status
    func checkConnection() {
        let path = monitor.currentPath
        updateConnectionStatus(path: path)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let networkConnectionRestored = Notification.Name("networkConnectionRestored")
    static let networkConnectionLost = Notification.Name("networkConnectionLost")
    static let syncCompleted = Notification.Name("syncCompleted")
    static let syncValidationError = Notification.Name("syncValidationError")
}


