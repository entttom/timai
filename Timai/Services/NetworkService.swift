//
//  NetworkService.swift
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

@MainActor
class NetworkService {
    
    enum APIError: Error, LocalizedError {
        case invalidCredentials(Error?)
        case noResponse(Error?)
        case invalidResponse(Error?)
        case requestError(Error?)
        case offlineNoCache
        
        var errorDescription: String? {
            switch self {
            case .invalidCredentials:
                return "Ungültige Zugangsdaten"
            case .noResponse:
                return "Keine Antwort vom Server"
            case .invalidResponse:
                return "Ungültige Serverantwort"
            case .requestError:
                return "Netzwerkfehler"
            case .offlineNoCache:
                return "Offline - Keine Daten im Cache"
            }
        }
    }
    
    static let shared = NetworkService()
    
    private let session: URLSession
    private let networkMonitor = NetworkMonitor.shared
    private let cacheManager = CacheManager.shared
    private let pendingOpsManager = PendingOperationsManager.shared
    
    private init() {
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Custom Date Decoder
    
    private var customDateDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Format 1: DateTime mit Timezone z.B. "2026-01-02T07:15:00+0000"
            let dateTimeFormatter = DateFormatter()
            dateTimeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            dateTimeFormatter.locale = Locale(identifier: "en_US_POSIX")
            if let date = dateTimeFormatter.date(from: dateString) {
                return date
            }
            
            // Format 2: Nur Datum z.B. "2025-10-27"
            let dateOnlyFormatter = DateFormatter()
            dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
            dateOnlyFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateOnlyFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = dateOnlyFormatter.date(from: dateString) {
                return date
            }
            
            // Format 3: ISO8601 Standard-Formate
            let isoFormatters: [ISO8601DateFormatter] = [
                {
                    let f = ISO8601DateFormatter()
                    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    return f
                }(),
                {
                    let f = ISO8601DateFormatter()
                    f.formatOptions = [.withInternetDateTime]
                    return f
                }(),
                ISO8601DateFormatter()
            ]
            
            for formatter in isoFormatters {
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            print("❌ [NetworkService] Konnte Datum nicht parsen: '\(dateString)'")
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string: \(dateString)")
        }
        return decoder
    }
    
    // MARK: - API Services
    
    /// Check version of kimai instance
    func checkVersion(for kimaiURL: URL, with user: User) async throws -> InstanceMetadata {
        let pingEndpoint = kimaiURL.appendingPathComponent("version")
        print("📡 [NetworkService] GET \(pingEndpoint)")
        
        var request = URLRequest(url: pingEndpoint)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        if let authToken = user.apiToken {
            let maskedToken = String(authToken.prefix(4)) + "..." + String(authToken.suffix(4))
            print("🔑 [NetworkService] Authorization: Bearer \(maskedToken)")
            request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidCredentials(nil)
            }
            
            print("📥 [NetworkService] HTTP Status: \(httpResponse.statusCode)")
            
            guard 200..<300 ~= httpResponse.statusCode else {
                print("❌ [NetworkService] HTTP Fehler \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 [NetworkService] Response Body: \(responseString)")
                }
                throw APIError.invalidCredentials(nil)
            }
            
            print("📦 [NetworkService] Daten empfangen: \(data.count) bytes")
            
            let decoder = JSONDecoder()
            let metadata = try decoder.decode(InstanceMetadata.self, from: data)
            print("✅ [NetworkService] Version Check erfolgreich dekodiert")
            return metadata
        } catch let error as APIError {
            throw error
        } catch {
            print("❌ [NetworkService] Request Fehler: \(error.localizedDescription)")
            throw APIError.requestError(error)
        }
    }
    
    /// Get timesheet for a user
    func getTimesheetFor(_ user: User) async throws -> [Activity] {
        if ProcessInfo.processInfo.arguments.contains("UI-Testing") {
            print("🧪 [NetworkService] UI-Testing Modus - verwende Mock-Daten")
            return []
        }
        
        // Try to fetch from API if online
        if networkMonitor.isConnected {
            print("📋 [NetworkService] Online - Lade Timesheets vom Server...")
            do {
        var urlComponents = URLComponents(url: user.apiEndpoint.appendingPathComponent("timesheets"), resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [
            URLQueryItem(name: "size", value: "100"),
            URLQueryItem(name: "orderBy", value: "begin"),
            URLQueryItem(name: "order", value: "DESC"),
            URLQueryItem(name: "full", value: "true")
        ]
        
        guard let url = urlComponents.url else {
            throw APIError.invalidResponse(nil)
        }
        
        print("📡 [NetworkService] GET \(url)")
        let data = try await performRESTRequest(url: url, method: "GET", body: nil, user: user)
        print("📦 [NetworkService] Timesheet Daten empfangen: \(data.count) bytes")
        
        let timesheets = try customDateDecoder.decode([Timesheet].self, from: data)
        print("✅ [NetworkService] \(timesheets.count) Timesheets erfolgreich dekodiert")
                
                // Cache the timesheets
                try await cacheManager.cache(timesheets, for: user, type: .timesheets)
        
        // Convert to Activity for backward compatibility
        let activities = timesheets.map { timesheet in
            Activity(
                recordId: timesheet.id,
                description: timesheet.description,
                customerName: timesheet.customerName,
                customerId: timesheet.project.customer.id,
                projectName: timesheet.projectName,
                projectId: timesheet.project.id,
                task: timesheet.task,
                activityId: timesheet.activity.id,
                startDateTime: timesheet.begin,
                endDateTime: timesheet.endDateTime
            )
        }
        print("✅ [NetworkService] \(activities.count) Activities konvertiert")
        return activities
            } catch {
                print("⚠️ [NetworkService] API-Fehler, versuche Cache: \(error)")
                // Fallthrough to cache
            }
        }
        
        // Load from cache (offline or API failed)
        print("💾 [NetworkService] Lade Timesheets aus Cache...")
        do {
            let cachedTimesheets = try await cacheManager.load([Timesheet].self, for: user, cacheType: .timesheets)
            let activities = cachedTimesheets.map { timesheet in
                Activity(
                    recordId: timesheet.id,
                    description: timesheet.description,
                    customerName: timesheet.customerName,
                    customerId: timesheet.project.customer.id,
                    projectName: timesheet.projectName,
                    projectId: timesheet.project.id,
                    task: timesheet.task,
                    activityId: timesheet.activity.id,
                    startDateTime: timesheet.begin,
                    endDateTime: timesheet.endDateTime
                )
            }
            print("💾 [NetworkService] \(activities.count) Timesheets aus Cache geladen")
            return activities
        } catch {
            print("❌ [NetworkService] Kein Cache verfügbar: \(error)")
            throw APIError.offlineNoCache
        }
    }
    
    /// Get customers
    func getCustomers(user: User) async throws -> [Customer] {
        // Try to fetch from API if online
        if networkMonitor.isConnected {
            do {
        let url = user.apiEndpoint.appendingPathComponent("customers")
        print("📡 [NetworkService] GET \(url)")
        
        let data = try await performRESTRequest(url: url, method: "GET", body: nil, user: user)
        print("📦 [NetworkService] Customers Daten empfangen: \(data.count) bytes")
        
        let decoder = JSONDecoder()
        let customers = try decoder.decode([Customer].self, from: data)
        print("✅ [NetworkService] \(customers.count) Customers dekodiert")
                
                // Cache the customers
                try await cacheManager.cache(customers, for: user, type: .customers)
                
                return customers
            } catch {
                print("⚠️ [NetworkService] API-Fehler, versuche Cache: \(error)")
            }
        }
        
        // Load from cache
        print("💾 [NetworkService] Lade Customers aus Cache...")
        do {
            let customers = try await cacheManager.load([Customer].self, for: user, cacheType: .customers)
            print("💾 [NetworkService] \(customers.count) Customers aus Cache geladen")
        return customers
        } catch {
            print("❌ [NetworkService] Kein Cache verfügbar")
            throw APIError.offlineNoCache
        }
    }
    
    /// Get projects for a customer
    func getProjects(customer: Customer, user: User) async throws -> [Project] {
        // Try to fetch from API if online
        if networkMonitor.isConnected {
            do {
        var urlComponents = URLComponents(url: user.apiEndpoint.appendingPathComponent("projects"), resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [
            URLQueryItem(name: "customer", value: "\(customer.id)"),
            URLQueryItem(name: "full", value: "true")
        ]
        
        guard let url = urlComponents.url else {
            throw APIError.invalidResponse(nil)
        }
        
        print("📡 [NetworkService] GET \(url)")
        
        let data = try await performRESTRequest(url: url, method: "GET", body: nil, user: user)
        print("📦 [NetworkService] Projects Daten empfangen: \(data.count) bytes")
        
        let projectCollections = try customDateDecoder.decode([ProjectCollection].self, from: data)
        print("✅ [NetworkService] \(projectCollections.count) ProjectCollections dekodiert")
        
        if projectCollections.isEmpty {
            return []
        }
        
        // Get detailed project info with budget
        var projectsWithBudget: [Project] = []
        
        for projectCollection in projectCollections {
            do {
                let project = try await getProjectDetails(projectId: projectCollection.id, customer: customer, user: user)
                projectsWithBudget.append(project)
            } catch {
                // Fallback: Verwende Project ohne Budget
                projectsWithBudget.append(projectCollection.toProject(customer: customer))
            }
        }
        
        print("✅ [NetworkService] \(projectsWithBudget.count) Projects mit Budget-Daten geladen")
                
                // Cache the projects for this customer
                try await cacheManager.cache(projectsWithBudget, for: user, type: .projectsForCustomer, identifier: "\(customer.id)")
                
        return projectsWithBudget
            } catch {
                print("⚠️ [NetworkService] API-Fehler, versuche Cache: \(error)")
            }
        }
        
        // Load from cache
        print("💾 [NetworkService] Lade Projects aus Cache...")
        do {
            let projects = try await cacheManager.load([Project].self, for: user, cacheType: .projectsForCustomer, identifier: "\(customer.id)")
            print("💾 [NetworkService] \(projects.count) Projects aus Cache geladen")
            return projects
        } catch {
            print("❌ [NetworkService] Kein Cache verfügbar")
            throw APIError.offlineNoCache
        }
    }
    
    /// Get project by ID with full details including budget
    func getProjectById(_ projectId: Int, user: User) async throws -> Project {
        let url = user.apiEndpoint.appendingPathComponent("projects/\(projectId)")
        print("📡 [NetworkService] GET \(url) (für Budget-Daten)")
        
        let data = try await performRESTRequest(url: url, method: "GET", body: nil, user: user)
        
        let projectCollection = try customDateDecoder.decode(ProjectCollection.self, from: data)
        
        // Customer-Objekt erstellen aus der ID (vereinfacht)
        let customer = Customer(id: projectCollection.customer, name: "", number: "", comment: nil, visible: true, billable: true, company: nil, country: "DE", currency: "EUR", color: nil)
        
        let project = projectCollection.toProject(customer: customer)
        print("✅ [NetworkService] Project \(project.name) mit Budget geladen: \(project.timeBudget ?? 0)s")
        return project
    }
    
    /// Get detailed project information including budget
    private func getProjectDetails(projectId: Int, customer: Customer, user: User) async throws -> Project {
        let url = user.apiEndpoint.appendingPathComponent("projects/\(projectId)")
        print("📡 [NetworkService] GET \(url) (für Budget-Daten)")
        
        let data = try await performRESTRequest(url: url, method: "GET", body: nil, user: user)
        
        let projectCollection = try customDateDecoder.decode(ProjectCollection.self, from: data)
        let project = projectCollection.toProject(customer: customer)
        print("✅ [NetworkService] Project \(project.name) mit Budget geladen: \(project.timeBudget ?? 0)s")
        return project
    }
    
    /// Get activities for a project
    func getActivities(projectId: Int?, user: User) async throws -> [ActivityDetails] {
        // Try to fetch from API if online
        if networkMonitor.isConnected {
            do {
        var urlComponents = URLComponents(url: user.apiEndpoint.appendingPathComponent("activities"), resolvingAgainstBaseURL: false)!
        var queryItems = [URLQueryItem(name: "full", value: "true")]
        if let projectId = projectId {
            queryItems.append(URLQueryItem(name: "project", value: "\(projectId)"))
        }
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw APIError.invalidResponse(nil)
        }
        
        let data = try await performRESTRequest(url: url, method: "GET", body: nil, user: user)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let activities = try decoder.decode([ActivityDetails].self, from: data)
                
                // Cache the activities for this project
                if let projectId = projectId {
                    try await cacheManager.cache(activities, for: user, type: .activitiesForProject, identifier: "\(projectId)")
                }
                
                return activities
            } catch {
                print("⚠️ [NetworkService] API-Fehler, versuche Cache: \(error)")
            }
        }
        
        // Load from cache
        if let projectId = projectId {
            print("💾 [NetworkService] Lade Activities aus Cache...")
            do {
                let activities = try await cacheManager.load([ActivityDetails].self, for: user, cacheType: .activitiesForProject, identifier: "\(projectId)")
                print("💾 [NetworkService] \(activities.count) Activities aus Cache geladen")
        return activities
            } catch {
                print("❌ [NetworkService] Kein Cache verfügbar")
                throw APIError.offlineNoCache
            }
        }
        
        throw APIError.offlineNoCache
    }
    
    /// Create a new timesheet
    func createTimesheet(form: TimesheetEditForm, user: User) async throws -> Timesheet {
        if networkMonitor.isConnected {
            // Online: Try to create directly
            do {
        var urlComponents = URLComponents(url: user.apiEndpoint.appendingPathComponent("timesheets"), resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [URLQueryItem(name: "full", value: "true")]
        
        guard let url = urlComponents.url else {
            throw APIError.invalidResponse(nil)
        }
        
        print("📡 [NetworkService] POST \(url)")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode(form)
        
        if let bodyString = String(data: body, encoding: .utf8) {
            print("📤 [NetworkService] Request Body: \(bodyString)")
        }
        
        let data = try await performRESTRequest(url: url, method: "POST", body: body, user: user)
        
        print("📦 [NetworkService] Create Response empfangen: \(data.count) bytes")
        
                let timesheet = try customDateDecoder.decode(Timesheet.self, from: data)
                print("✅ [NetworkService] Timesheet erfolgreich erstellt mit ID: \(timesheet.id)")
                
                // Update cache with new timesheet
                await updateCacheAfterCreate(timesheet: timesheet, user: user)
                
                return timesheet
            } catch {
                print("❌ [NetworkService] Online-Create fehlgeschlagen: \(error)")
                
                // Fallback to offline mode
                let tempId = UUID().uuidString
                pendingOpsManager.addOperation(.createTimesheet(form: form, tempId: tempId))
                print("📥 [NetworkService] Create fehlgeschlagen - zur Pending Queue hinzugefügt (tempId: \(tempId))")
                
                let tempTimesheet = await createTemporaryTimesheet(from: form, tempId: tempId, user: user)
                await updateCacheAfterCreate(timesheet: tempTimesheet, user: user)
                
                return tempTimesheet
            }
        } else {
            // Offline: Add to pending operations
            let tempId = UUID().uuidString
            pendingOpsManager.addOperation(.createTimesheet(form: form, tempId: tempId))
            print("📥 [NetworkService] Offline - Timesheet zur Pending Queue hinzugefügt (tempId: \(tempId))")
            
            // Create a temporary timesheet for display
            let tempTimesheet = await createTemporaryTimesheet(from: form, tempId: tempId, user: user)
            
            // Optimistically add to cache
            await updateCacheAfterCreate(timesheet: tempTimesheet, user: user)
            
            return tempTimesheet
        }
    }
    
    /// Update an existing timesheet
    func updateTimesheet(id: Int, form: TimesheetEditForm, user: User) async throws -> Timesheet {
        if networkMonitor.isConnected {
            // Online: Try to update directly
            do {
        var urlComponents = URLComponents(url: user.apiEndpoint.appendingPathComponent("timesheets/\(id)"), resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [URLQueryItem(name: "full", value: "true")]
        
        guard let url = urlComponents.url else {
            throw APIError.invalidResponse(nil)
        }
        
        print("📡 [NetworkService] PATCH \(url)")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode(form)
        
        let data = try await performRESTRequest(url: url, method: "PATCH", body: body, user: user)
        
        print("📦 [NetworkService] Update Response empfangen: \(data.count) bytes")
        
                let timesheet = try customDateDecoder.decode(Timesheet.self, from: data)
                print("✅ [NetworkService] Timesheet erfolgreich aktualisiert mit ID: \(timesheet.id)")
                
                // Update cache with modified timesheet
                await updateCacheAfterUpdate(timesheet: timesheet, user: user)
                
                return timesheet
            } catch {
                print("❌ [NetworkService] Online-Update fehlgeschlagen: \(error)")
                
                // Fallback to offline mode
                pendingOpsManager.addOperation(.updateTimesheet(id: id, form: form))
                print("📥 [NetworkService] Update fehlgeschlagen - zur Pending Queue hinzugefügt (id: \(id))")
                
                let tempTimesheet = await createTemporaryTimesheet(from: form, tempId: "\(id)", user: user, existingId: id)
                await updateCacheAfterUpdate(timesheet: tempTimesheet, user: user)
                
                return tempTimesheet
            }
        } else {
            // Offline: Add to pending operations
            pendingOpsManager.addOperation(.updateTimesheet(id: id, form: form))
            print("📥 [NetworkService] Offline - Timesheet Update zur Pending Queue hinzugefügt (id: \(id))")
            
            // Create a temporary timesheet for display
            let tempTimesheet = await createTemporaryTimesheet(from: form, tempId: "\(id)", user: user, existingId: id)
            
            // Optimistically update in cache
            await updateCacheAfterUpdate(timesheet: tempTimesheet, user: user)
            
            return tempTimesheet
        }
    }
    
    /// Delete a timesheet
    func deleteTimesheet(id: Int, user: User) async throws {
        print("🗑️ [NetworkService] deleteTimesheet aufgerufen für ID: \(id)")
        print("🌐 [NetworkService] Netzwerk-Status: \(networkMonitor.isConnected ? "Online" : "Offline")")
        
        if networkMonitor.isConnected {
            // Online: Try to delete directly
            do {
                let url = user.apiEndpoint.appendingPathComponent("timesheets/\(id)")
                print("📡 [NetworkService] DELETE \(url)")
                
                _ = try await performRESTRequest(url: url, method: "DELETE", body: nil, user: user)
                print("✅ [NetworkService] DELETE erfolgreich - Timesheet \(id) gelöscht")
                
                // Update cache by removing the deleted item
                await updateCacheAfterDelete(id: id, user: user)
            } catch {
                print("❌ [NetworkService] Online-Delete fehlgeschlagen: \(error)")
                
                // Add to pending operations even if online request failed
                print("📥 [NetworkService] Füge fehlgeschlagene Delete-Operation zur Queue hinzu")
                pendingOpsManager.addOperation(.deleteTimesheet(id: id))
                print("✅ [NetworkService] Operation hinzugefügt - Queue hat jetzt \(pendingOpsManager.pendingCount) Operationen")
                
                // Still update cache optimistically
                await updateCacheAfterDelete(id: id, user: user)
                
                // Don't throw - let it be handled as pending operation
            }
        } else {
            // Offline: Add to pending operations
            print("📥 [NetworkService] Offline - füge Delete-Operation zur Queue hinzu")
            pendingOpsManager.addOperation(.deleteTimesheet(id: id))
            print("✅ [NetworkService] Operation hinzugefügt - Queue hat jetzt \(pendingOpsManager.pendingCount) Operationen")
            
            // Optimistically update cache
            await updateCacheAfterDelete(id: id, user: user)
        }
    }
    
    /// Update cache after creating a timesheet
    private func updateCacheAfterCreate(timesheet: Timesheet, user: User) async {
        do {
            var cachedTimesheets = (try? await cacheManager.load([Timesheet].self, for: user, cacheType: .timesheets)) ?? []
            
            // Check if timesheet already exists (avoid duplicates)
            if !cachedTimesheets.contains(where: { $0.id == timesheet.id }) {
                cachedTimesheets.insert(timesheet, at: 0) // Add at beginning (newest first)
            }
            
            // Limit cache size
            let maxEntries = CacheSettings.maxCacheEntries
            if cachedTimesheets.count > maxEntries {
                cachedTimesheets = Array(cachedTimesheets.prefix(maxEntries))
            }
            
            try await cacheManager.cache(cachedTimesheets, for: user, type: .timesheets)
            print("💾 [NetworkService] Cache aktualisiert - Timesheet \(timesheet.id) hinzugefügt")
        } catch {
            print("⚠️ [NetworkService] Konnte Cache nicht aktualisieren: \(error)")
        }
    }
    
    /// Update cache after updating a timesheet
    private func updateCacheAfterUpdate(timesheet: Timesheet, user: User) async {
        do {
            var cachedTimesheets = try await cacheManager.load([Timesheet].self, for: user, cacheType: .timesheets)
            
            // Find and replace the updated timesheet
            if let index = cachedTimesheets.firstIndex(where: { $0.id == timesheet.id }) {
                cachedTimesheets[index] = timesheet
                try await cacheManager.cache(cachedTimesheets, for: user, type: .timesheets)
                print("💾 [NetworkService] Cache aktualisiert - Timesheet \(timesheet.id) aktualisiert")
            }
        } catch {
            print("⚠️ [NetworkService] Konnte Cache nicht aktualisieren: \(error)")
        }
    }
    
    /// Update cache after deleting a timesheet
    private func updateCacheAfterDelete(id: Int, user: User) async {
        do {
            var cachedTimesheets = try await cacheManager.load([Timesheet].self, for: user, cacheType: .timesheets)
            cachedTimesheets.removeAll { $0.id == id }
            try await cacheManager.cache(cachedTimesheets, for: user, type: .timesheets)
            print("💾 [NetworkService] Cache aktualisiert - Timesheet \(id) entfernt")
        } catch {
            print("⚠️ [NetworkService] Konnte Cache nicht aktualisieren: \(error)")
        }
    }
    
    /// Preload all reference data for offline use
    func preloadReferenceData(for user: User) async throws {
        print("📥 [NetworkService] Starte Preload aller Referenzdaten...")
        
        // 1. Load customers
        print("📥 [NetworkService] Lade Customers...")
        let customers = try await getCustomers(user: user)
        print("✅ [NetworkService] \(customers.count) Customers geladen und gecacht")
        
        // 2. Load all projects for each customer
        print("📥 [NetworkService] Lade Projects für alle Customers...")
        var totalProjects = 0
        for customer in customers {
            do {
                let projects = try await getProjects(customer: customer, user: user)
                totalProjects += projects.count
                print("  ✅ Customer '\(customer.name)': \(projects.count) Projects")
                
                // 3. Load activities for each project
                for project in projects {
                    do {
                        let activities = try await getActivities(projectId: project.id, user: user)
                        print("    ✅ Project '\(project.name)': \(activities.count) Activities")
                    } catch {
                        print("    ⚠️ Project '\(project.name)': Activities konnten nicht geladen werden")
                    }
                }
            } catch {
                print("  ⚠️ Customer '\(customer.name)': Projects konnten nicht geladen werden")
            }
        }
        
        print("✅ [NetworkService] Preload abgeschlossen: \(customers.count) Customers, \(totalProjects) Projects")
    }
    
    /// Get all users (for reports with all users)
    func getAllUsers(user: User) async throws -> [TimesheetUser] {
        let url = user.apiEndpoint.appendingPathComponent("users")
        print("📡 [NetworkService] GET \(url)")
        
        let data = try await performRESTRequest(url: url, method: "GET", body: nil, user: user)
        print("📦 [NetworkService] Users Daten empfangen: \(data.count) bytes")
        
        let decoder = JSONDecoder()
        let users = try decoder.decode([TimesheetUser].self, from: data)
        print("✅ [NetworkService] \(users.count) Users dekodiert")
        return users
    }
    
    /// Get timesheets with full project objects (including budget)
    func getTimesheetsWithProjects(_ user: User) async throws -> [Timesheet] {
        if ProcessInfo.processInfo.arguments.contains("UI-Testing") {
            print("🧪 [NetworkService] UI-Testing Modus - keine Timesheets verfügbar")
            return []
        }
        
        // Try to fetch from API if online
        if networkMonitor.isConnected {
            do {
                print("📋 [NetworkService] Online - Lade Timesheets mit Projekten vom Server...")
        var urlComponents = URLComponents(url: user.apiEndpoint.appendingPathComponent("timesheets"), resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [
            URLQueryItem(name: "size", value: "100"),
            URLQueryItem(name: "orderBy", value: "begin"),
            URLQueryItem(name: "order", value: "DESC"),
            URLQueryItem(name: "full", value: "true")
        ]
        
        guard let url = urlComponents.url else {
            throw APIError.invalidResponse(nil)
        }
        
        print("📡 [NetworkService] GET \(url)")
        
        let data = try await performRESTRequest(url: url, method: "GET", body: nil, user: user)
        print("📦 [NetworkService] Timesheet Daten empfangen: \(data.count) bytes")
        
        let timesheets = try customDateDecoder.decode([Timesheet].self, from: data)
        print("✅ [NetworkService] \(timesheets.count) Timesheets mit Projekten dekodiert")
        
                // Cache the timesheets
                try await cacheManager.cache(timesheets, for: user, type: .timesheets)
                
                return timesheets
            } catch {
                print("⚠️ [NetworkService] API-Fehler, versuche Cache: \(error)")
            }
        }
        
        // Load from cache
        print("💾 [NetworkService] Lade Timesheets aus Cache...")
        do {
            let timesheets = try await cacheManager.load([Timesheet].self, for: user, cacheType: .timesheets)
            print("💾 [NetworkService] \(timesheets.count) Timesheets aus Cache geladen")
        return timesheets
        } catch {
            print("❌ [NetworkService] Kein Cache verfügbar")
            throw APIError.offlineNoCache
        }
    }
    
    // MARK: - Helper Methods
    
    /// Create a temporary timesheet for offline operations
    private func createTemporaryTimesheet(from form: TimesheetEditForm, tempId: String, user: User, existingId: Int? = nil) async -> Timesheet {
        // Parse dates from form
        let formatter = ISO8601DateFormatter()
        let begin = form.begin.flatMap { formatter.date(from: $0) } ?? Date()
        let end = form.end.flatMap { formatter.date(from: $0) }
        
        // Calculate duration
        let duration: Int? = {
            if let end = end {
                return Int(end.timeIntervalSince(begin))
            }
            return nil
        }()
        
        // Create minimal user
        let tempUser = TimesheetUser(id: 0, alias: nil, title: nil, username: "Current User")
        
        // Try to load real customer, project, and activity from cache
        var customer: Customer?
        var project: Project?
        var activity: ActivityDetails?
        
        // Try to load customers
        if let cachedCustomers = try? await cacheManager.load([Customer].self, for: user, cacheType: .customers) {
            print("🔍 [NetworkService] Gefundene Customers im Cache: \(cachedCustomers.count)")
            
            // Search for the project in all customer caches
            for cachedCustomer in cachedCustomers {
                if let projects = try? await cacheManager.load([Project].self, for: user, cacheType: .projectsForCustomer, identifier: "\(cachedCustomer.id)") {
                    if let foundProject = projects.first(where: { $0.id == form.project }) {
                        customer = cachedCustomer
                        project = foundProject
                        print("✅ [NetworkService] Customer & Project aus Cache geladen: \(cachedCustomer.name) / \(foundProject.name)")
                        break
                    }
                }
            }
            
            // Try to load activity
            if let activities = try? await cacheManager.load([ActivityDetails].self, for: user, cacheType: .activitiesForProject, identifier: "\(form.project)") {
                activity = activities.first(where: { $0.id == form.activity })
                if let activity = activity {
                    print("✅ [NetworkService] Activity aus Cache geladen: \(activity.name)")
                }
            }
        }
        
        // Fallback to dummy data if cache loading failed
        if customer == nil {
            print("⚠️ [NetworkService] Konnte Customer nicht aus Cache laden - verwende Fallback")
            customer = Customer(
                id: 0,
                name: "Offline-Eintrag",
                number: nil,
                comment: nil,
                visible: true,
                billable: true,
                company: nil,
                country: "DE",
                currency: "EUR",
                color: nil
            )
        }
        
        if project == nil {
            print("⚠️ [NetworkService] Konnte Project nicht aus Cache laden - verwende Fallback")
            project = Project(
                id: form.project,
                customer: customer!,
                name: "Project \(form.project)",
                orderNumber: nil,
                start: nil,
                end: nil,
                visible: true,
                billable: true,
                color: nil,
                budget: nil,
                timeBudget: nil,
                budgetType: nil
            )
        }
        
        if activity == nil {
            print("⚠️ [NetworkService] Konnte Activity nicht aus Cache laden - verwende Fallback")
            activity = ActivityDetails(
                id: form.activity,
                project: nil,
                name: "Activity \(form.activity)",
                comment: nil,
                visible: true,
                billable: true,
                number: nil,
                color: nil
            )
        }
        
        // Use hash of tempId as negative ID to make it unique and identifiable
        let tempIdHash = existingId ?? -(abs(tempId.hashValue) % 1_000_000)
        
        return Timesheet(
            id: tempIdHash,
            begin: begin,
            end: end,
            duration: duration,
            user: tempUser,
            activity: activity!,
            project: project!,
            description: form.description,
            rate: 0.0,
            internalRate: nil,
            fixedRate: form.fixedRate,
            hourlyRate: form.hourlyRate,
            exported: false,
            billable: form.billable ?? true,
            tags: form.tags.map { [$0] } ?? []
        )
    }
    
    // MARK: - Private Helper
    
    private func performRESTRequest(url: URL, method: String, body: Data?, user: User) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        if let authToken = user.apiToken {
            request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResp = response as? HTTPURLResponse else {
                throw APIError.noResponse(nil)
            }
            
            guard 200..<300 ~= httpResp.statusCode else {
                print("❌ [NetworkService] HTTP Status code: \(httpResp.statusCode)")
                
                // Bei 400 Error, zeige Response Body für Details
                if httpResp.statusCode == 400,
                   let errorMessage = String(data: data, encoding: .utf8) {
                    print("❌ [NetworkService] 400 Bad Request - Server Response:")
                    print("📄 [NetworkService] \(errorMessage)")
                }
                
                if httpResp.statusCode == 401 {
                    throw APIError.invalidCredentials(nil)
                } else {
                    throw APIError.requestError(nil)
                }
            }
            
            return data
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.requestError(error)
        }
    }
}

