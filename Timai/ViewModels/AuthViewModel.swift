//
//  AuthViewModel.swift
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
import SwiftUI
import KeychainAccess

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isPreloadingData = false
    
    private let keychain = Keychain(service: Bundle.main.bundleIdentifier!)
    private let networkService = NetworkService.shared
    private let instanceManager = InstanceManager.shared
    
    // MARK: - Auto Login
    
    func checkAutoLogin() {
        print("🔑 [AuthViewModel] Prüfe gespeicherte Zugangsdaten...")
        
        // Check if there's an active instance
        guard let activeInstance = instanceManager.activeInstance else {
            print("ℹ️ [AuthViewModel] Keine aktive Instanz - zeige Login")
            return
        }
        
        // Get token for active instance
        guard let apiToken = activeInstance.apiToken else {
            print("ℹ️ [AuthViewModel] Kein API Token für aktive Instanz - zeige Login")
            return
        }
        
        print("✅ [AuthViewModel] Aktive Instanz gefunden: '\(activeInstance.name)'")
        print("✅ [AuthViewModel] API Token gefunden (Länge: \(apiToken.count) Zeichen)")
        
        let user = User(
            apiEndpoint: activeInstance.apiEndpoint,
            apiToken: apiToken,
            instanceId: activeInstance.id
        )
        self.currentUser = user
        self.isAuthenticated = true
        
        print("🚀 [AuthViewModel] Auto-Login erfolgreich - öffne App")
        
        // Lade User-Details mit Rollen im Hintergrund
        Task {
            await loadCurrentUserDetails()
        }
    }
    
    // MARK: - Login
    
    func login(kimaiURL: URL, apiToken: String, instanceName: String? = nil) async {
        guard !kimaiURL.absoluteString.isEmpty, !apiToken.isEmpty else {
            print("❌ [AuthViewModel] Fehlende Eingaben: URL oder API Token fehlt")
            errorMessage = "Bitte URL und API Token eingeben"
            return
        }
        
        print("🔐 [AuthViewModel] Starte Login-Versuch...")
        print("🌐 [AuthViewModel] URL: \(kimaiURL)")
        print("🔑 [AuthViewModel] API Token Länge: \(apiToken.count) Zeichen")
        
        isLoading = true
        errorMessage = nil
        
        // Prüfe ob URL bereits mit /api endet
        let api: URL
        if kimaiURL.absoluteString.hasSuffix("/api") || kimaiURL.absoluteString.hasSuffix("/api/") {
            print("ℹ️ [AuthViewModel] URL endet bereits mit /api - verwende direkt")
            api = kimaiURL
        } else {
            print("ℹ️ [AuthViewModel] Füge /api zur URL hinzu")
            api = kimaiURL.appendingPathComponent("api")
        }
        print("📡 [AuthViewModel] Vollständiger API Endpoint: \(api)")
        
        let user = User(apiEndpoint: api, apiToken: apiToken)
        
        do {
            let metadata = try await networkService.checkVersion(for: api, with: user)
            
            print("✅ [AuthViewModel] Version Check erfolgreich")
            print("📋 [AuthViewModel] Kimai Version: \(metadata.version)")
            if let versionId = metadata.versionId {
                print("📋 [AuthViewModel] Kimai Version ID: \(versionId)")
            }
            print("📋 [AuthViewModel] Kimai Name: \(metadata.displayName)")
            print("📋 [AuthViewModel] Copyright: \(metadata.copyright)")
            
            let minimumRequiredVersion = Bundle.main.object(forInfoDictionaryKey: "MinimumRequiredKimaiVersion") as? String ?? "2.0.0"
            print("📋 [AuthViewModel] Mindestversion erforderlich: \(minimumRequiredVersion)")
            
            if metadata.version.compare(minimumRequiredVersion, options: .numeric) != .orderedAscending {
                print("✅ [AuthViewModel] Version ist kompatibel - Login erfolgreich")
                
                // Create or update instance
                let instance = KimaiInstance(
                    name: instanceName ?? "Kimai Instance",
                    apiEndpoint: api,
                    isActive: false  // Will be set to true by switchToInstance
                )
                
                // Save token to instance
                try instance.saveToken(apiToken)
                
                // Add or update instance in manager
                if let existingInstance = instanceManager.instances.first(where: { $0.apiEndpoint == api }) {
                    // Update existing instance
                    var updatedInstance = existingInstance
                    updatedInstance.name = instanceName ?? existingInstance.name
                    instanceManager.updateInstance(updatedInstance)
                    instanceManager.switchToInstance(updatedInstance)
                    
                    // Create user with instance ID
                    self.currentUser = User(
                        apiEndpoint: api,
                        apiToken: apiToken,
                        instanceId: updatedInstance.id
                    )
                } else {
                    // Add new instance
                    instanceManager.addInstance(instance)
                    // Switch to the newly added instance
                    if let addedInstance = instanceManager.instances.first(where: { $0.id == instance.id }) {
                        instanceManager.switchToInstance(addedInstance)
                    }
                    
                    // Create user with instance ID
                    self.currentUser = User(
                        apiEndpoint: api,
                        apiToken: apiToken,
                        instanceId: instance.id
                    )
                }
                
                // Lade User-Details mit Rollen
                await loadCurrentUserDetails()
                
                self.isAuthenticated = true
                
                // Preload reference data in background
                Task {
                    await preloadReferenceData()
                }
            } else {
                print("⚠️ [AuthViewModel] Version zu alt: \(metadata.version) < \(minimumRequiredVersion)")
                errorMessage = "\("error.message.unsupportedVersion".localized()): \(metadata.version)"
            }
        } catch let error as NetworkService.APIError {
            print("❌ [AuthViewModel] Login fehlgeschlagen")
            switch error {
            case .invalidCredentials:
                print("❌ [AuthViewModel] Ungültige Zugangsdaten (HTTP 401)")
                errorMessage = "error.message.wrongCredentials".localized()
            case .noResponse:
                print("❌ [AuthViewModel] Keine Antwort vom Server")
                errorMessage = "error.message.endpointConnectionError".localized()
            case .invalidResponse:
                print("❌ [AuthViewModel] Ungültige Antwort vom Server")
                errorMessage = "error.message.endpointConnectionError".localized()
            case .requestError:
                print("❌ [AuthViewModel] Netzwerk-Fehler")
                errorMessage = "error.message.endpointConnectionError".localized()
            case .offlineNoCache:
                print("❌ [AuthViewModel] Offline ohne Cache")
                errorMessage = "error.message.endpointConnectionError".localized()
            }
        } catch {
            print("❌ [AuthViewModel] Unerwarteter Fehler: \(error)")
            errorMessage = "Ein unerwarteter Fehler ist aufgetreten"
        }
        
        isLoading = false
    }
    
    // MARK: - Load User Details
    
    private func loadCurrentUserDetails() async {
        guard let user = currentUser else {
            print("❌ [AuthViewModel] Kein User - kann Details nicht laden")
            return
        }
        
        do {
            let userDetails = try await networkService.getCurrentUser(user: user)
            var updatedUser = user
            updatedUser.userDetails = userDetails
            self.currentUser = updatedUser
            print("✅ [AuthViewModel] User-Details geladen für: \(userDetails.username)")
        } catch {
            print("⚠️ [AuthViewModel] Konnte User-Details nicht laden: \(error)")
            // Nicht kritisch - App kann trotzdem verwendet werden
        }
    }
    
    // MARK: - Preload Data
    
    func preloadReferenceData() async {
        guard let user = currentUser else {
            print("❌ [AuthViewModel] Kein User - Preload abgebrochen")
            return
        }
        
        // Check if already preloaded
        let hasPreloaded = UserDefaults.standard.bool(forKey: "hasPreloadedReferenceData")
        if hasPreloaded {
            print("ℹ️ [AuthViewModel] Referenzdaten bereits vorgeladen - überspringe")
            return
        }
        
        print("🔄 [AuthViewModel] Starte Preload von Referenzdaten...")
        isPreloadingData = true
        
        do {
            try await networkService.preloadReferenceData(for: user)
            UserDefaults.standard.set(true, forKey: "hasPreloadedReferenceData")
            print("✅ [AuthViewModel] Referenzdaten erfolgreich vorgeladen")
        } catch {
            print("❌ [AuthViewModel] Fehler beim Preload: \(error)")
            // Don't fail - user can still use the app
        }
        
        isPreloadingData = false
    }
    
    func forcePreloadReferenceData() async throws {
        guard let user = currentUser else {
            print("❌ [AuthViewModel] Kein User - Preload abgebrochen")
            throw NSError(domain: "AuthViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kein User verfügbar"])
        }
        
        print("🔄 [AuthViewModel] Erzwinge Preload von Referenzdaten...")
        isPreloadingData = true
        
        do {
            try await networkService.preloadReferenceData(for: user)
            UserDefaults.standard.set(true, forKey: "hasPreloadedReferenceData")
            print("✅ [AuthViewModel] Referenzdaten erfolgreich vorgeladen")
        } catch {
            print("❌ [AuthViewModel] Fehler beim Preload: \(error)")
            isPreloadingData = false
            throw error
        }
        
        isPreloadingData = false
    }
    
    // MARK: - Instance Management
    
    /// Switch to a different instance
    func switchToInstance(_ instance: KimaiInstance) async {
        print("🔄 [AuthViewModel] Wechsle zu Instanz: '\(instance.name)'")
        
        guard let apiToken = instance.apiToken else {
            print("❌ [AuthViewModel] Kein Token für Instanz '\(instance.name)'")
            errorMessage = "Keine Zugangsdaten für diese Instanz gefunden"
            return
        }
        
        // Switch instance in manager
        instanceManager.switchToInstance(instance)
        
        // Create new user
        let user = User(
            apiEndpoint: instance.apiEndpoint,
            apiToken: apiToken,
            instanceId: instance.id
        )
        
        self.currentUser = user
        
        // Reload user details
        await loadCurrentUserDetails()
        
        print("✅ [AuthViewModel] Instanzwechsel abgeschlossen")
    }
    
    // MARK: - Logout
    
    func logout() {
        print("🚪 [AuthViewModel] Logout wird durchgeführt...")
        
        guard let activeInstance = instanceManager.activeInstance else {
            print("⚠️ [AuthViewModel] Keine aktive Instanz zum Ausloggen")
            self.currentUser = nil
            self.isAuthenticated = false
            return
        }
        
        Task {
            do {
                // Delete instance (includes token and cache cleanup)
                try await instanceManager.deleteInstance(activeInstance)
                print("✅ [AuthViewModel] Instanz gelöscht: '\(activeInstance.name)'")
                
                // Check if there are more instances
                if let nextInstance = instanceManager.activeInstance {
                    // Switch to next instance
                    print("🔄 [AuthViewModel] Wechsle zu nächster Instanz: '\(nextInstance.name)'")
                    await switchToInstance(nextInstance)
                } else {
                    // No more instances, show login
                    print("🔓 [AuthViewModel] Keine Instanzen mehr - zeige Login")
                    UserDefaults.standard.removeObject(forKey: "hasPreloadedReferenceData")
                    self.currentUser = nil
                    self.isAuthenticated = false
                }
            } catch let error {
                print("❌ [AuthViewModel] Logout fehlgeschlagen: \(error.localizedDescription)")
                errorMessage = "Logout fehlgeschlagen"
            }
        }
    }
}

