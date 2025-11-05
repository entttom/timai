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
    
    // MARK: - Auto Login
    
    func checkAutoLogin() {
        print("🔑 [AuthViewModel] Prüfe gespeicherte Zugangsdaten...")
        
        guard let token = try? keychain.get("apiToken"),
              let apiToken = token else {
            print("ℹ️ [AuthViewModel] Kein API Token gefunden - zeige Login")
            return
        }
        
        print("✅ [AuthViewModel] API Token im Keychain gefunden (Länge: \(apiToken.count) Zeichen)")
        
        guard let currentUserDict = UserDefaults.standard.dictionary(forKey: "currentUser"),
              let endpoint = currentUserDict["endpoint"] as? String,
              let endpointURL = URL(string: endpoint) else {
            print("❌ [AuthViewModel] Endpoint ungültig - zeige Login")
            return
        }
        
        print("✅ [AuthViewModel] Gespeicherten Endpoint gefunden: \(endpointURL)")
        
        let user = User(apiEndpoint: endpointURL, apiToken: apiToken)
        self.currentUser = user
        self.isAuthenticated = true
        
        print("🚀 [AuthViewModel] Auto-Login erfolgreich - öffne App")
    }
    
    // MARK: - Login
    
    func login(kimaiURL: URL, apiToken: String) async {
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
                
                // Speichere Credentials
                UserDefaults.standard.set(
                    ["endpoint": String(describing: user.apiEndpoint)],
                    forKey: "currentUser"
                )
                
                self.currentUser = user
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
    
    // MARK: - Logout
    
    func logout() {
        print("🚪 [AuthViewModel] Logout wird durchgeführt...")
        
        do {
            try keychain.remove("apiToken")
            print("✅ [AuthViewModel] API Token aus Keychain entfernt")
            UserDefaults.standard.removeObject(forKey: "currentUser")
            print("✅ [AuthViewModel] User Daten aus UserDefaults entfernt")
            UserDefaults.standard.removeObject(forKey: "hasPreloadedReferenceData")
            print("✅ [AuthViewModel] Preload-Flag zurückgesetzt")
            print("🔓 [AuthViewModel] Logout erfolgreich - zeige Login")
            
            self.currentUser = nil
            self.isAuthenticated = false
        } catch let error {
            print("❌ [AuthViewModel] Logout fehlgeschlagen: \(error.localizedDescription)")
            errorMessage = "Logout fehlgeschlagen"
        }
    }
}

