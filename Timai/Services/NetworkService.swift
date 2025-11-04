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
            }
        }
    }
    
    static let shared = NetworkService()
    
    private let session: URLSession
    
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
        
        print("📋 [NetworkService] Lade Timesheets...")
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
    }
    
    /// Get customers
    func getCustomers(user: User) async throws -> [Customer] {
        let url = user.apiEndpoint.appendingPathComponent("customers")
        print("📡 [NetworkService] GET \(url)")
        
        let data = try await performRESTRequest(url: url, method: "GET", body: nil, user: user)
        print("📦 [NetworkService] Customers Daten empfangen: \(data.count) bytes")
        
        let decoder = JSONDecoder()
        let customers = try decoder.decode([Customer].self, from: data)
        print("✅ [NetworkService] \(customers.count) Customers dekodiert")
        return customers
    }
    
    /// Get projects for a customer
    func getProjects(customer: Customer, user: User) async throws -> [Project] {
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
        return projectsWithBudget
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
        return activities
    }
    
    /// Create a new timesheet
    func createTimesheet(form: TimesheetEditForm, user: User) async throws -> Timesheet {
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
        return timesheet
    }
    
    /// Update an existing timesheet
    func updateTimesheet(id: Int, form: TimesheetEditForm, user: User) async throws -> Timesheet {
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
        return timesheet
    }
    
    /// Delete a timesheet
    func deleteTimesheet(id: Int, user: User) async throws {
        let url = user.apiEndpoint.appendingPathComponent("timesheets/\(id)")
        print("📡 [NetworkService] DELETE \(url)")
        
        _ = try await performRESTRequest(url: url, method: "DELETE", body: nil, user: user)
        print("✅ [NetworkService] DELETE erfolgreich - Timesheet \(id) gelöscht")
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
        
        print("📋 [NetworkService] Lade Timesheets mit Projekten...")
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
        
        return timesheets
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

