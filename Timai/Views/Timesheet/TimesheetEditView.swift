//
//  TimesheetEditView.swift
//  Timai
//
//  Copyright (c) 2025 Dr. Thomas Entner.
//  All rights reserved.
//
//  Licensed under the Business Source License 1.1.
//  Usage is free for non-commercial and personal use.
//  Commercial use requires a commercial license.
//
import SwiftUI

struct TimesheetEditView: View {
    enum Mode {
        case create
        case edit(activity: Activity)
        
        var isEdit: Bool {
            if case .edit = self {
                return true
            }
            return false
        }
    }
    
    let mode: Mode
    let onSaved: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var editViewModel = TimesheetEditViewModel()
    
    @State private var selectedCustomerId: Int?
    @State private var selectedProjectId: Int?
    @State private var selectedActivityId: Int?
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600) // +1 Stunde als Standard
    @State private var descriptionText = ""
    @State private var tags: [String] = []
    @State private var createdTagIds: [String: Int] = [:] // Tracking: Tag-Name -> Tag-ID für neu erstellte Tags
    @State private var initialTags: [String] = [] // Initiale Tags beim Öffnen (für Cleanup)
    @State private var hasBeenSaved = false // Flag, um zu verhindern, dass Cleanup nach erfolgreichem Speichern läuft
    @State private var fixedRate: String = ""
    @State private var hourlyRate: String = ""
    @State private var billable = true
    @State private var showAdvancedSettings = false
    @State private var showToast = false
    @State private var isInitializing = false
    @State private var showNoDataWarning = false
    @State private var isAdjustingDates = false // Verhindert Rekursion
    
    var body: some View {
        Form {
            // Warning if no data available
            if editViewModel.customers.isEmpty && !editViewModel.isLoadingCustomers && showNoDataWarning {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        
                        Text("timesheetEdit.warning.noData.title".localized())
                            .font(.headline)
                        
                        Text("timesheetEdit.warning.noData.message".localized())
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
            
            customerSection
            
            if selectedCustomerId != nil || mode.isEdit {
                projectSection
            }
            
            if selectedProjectId != nil || mode.isEdit {
                activitySection
            }
            
            if selectedActivityId != nil || mode.isEdit {
                timeSection
                descriptionSection
                tagsSection
                advancedSettingsSection
            }
        }
        .navigationTitle(mode.isEdit ? "timesheetEdit.navigationTitle.edit".localized() : "timesheetEdit.navigationTitle.create".localized())
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onDisappear {
            // Wird auch beim Swipe-to-Dismiss aufgerufen
            if !hasBeenSaved {
                Task {
                    await cleanupUnusedTags()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("timesheetEdit.button.cancel".localized()) {
                    Task {
                        await cleanupUnusedTags()
                    }
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("timesheetEdit.button.save".localized()) {
                    Task {
                        await saveTimesheet()
                    }
                }
                .disabled(!canSave)
            }
        }
        .task {
            if let user = authViewModel.currentUser {
                editViewModel.setUser(user)
                await editViewModel.loadCustomers()
                await editViewModel.loadKnownTags()
                
                // Show warning if no customers loaded
                if editViewModel.customers.isEmpty {
                    showNoDataWarning = true
                }
                
                // Load existing data for edit mode
                if case .edit(let activity) = mode {
                    isInitializing = true
                    
                    startDate = activity.startDateTime
                    endDate = activity.endDateTime
                    descriptionText = activity.description ?? ""
                    tags = activity.tags ?? []
                    initialTags = activity.tags ?? [] // Speichere initiale Tags für Cleanup
                    
                    // For offline-created entries, customer ID might be 0
                    // In that case, try to find customer from project cache
                    var effectiveCustomerId = activity.customerId
                    if effectiveCustomerId == 0 {
                        effectiveCustomerId = await editViewModel.findCustomerIdForProject(activity.projectId)
                    }
                    
                    // Pre-select customer, project, and activity
                    let (customer, project, activityDetails) = await editViewModel.loadAndPreselect(
                        customerId: effectiveCustomerId,
                        projectId: activity.projectId,
                        activityId: activity.activityId
                    )
                    
                    // Set selected IDs after data is loaded
                    selectedCustomerId = customer?.id
                    selectedProjectId = project?.id
                    selectedActivityId = activityDetails?.id
                    
                    // Kleine Verzögerung für UI-Update
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 Sekunden
                    
                    isInitializing = false
                }
            }
        }
        .overlay {
            if editViewModel.isSaving {
                LoadingOverlay()
            }
        }
        .toast(
            isShowing: $showToast,
            message: editViewModel.errorMessage ?? "",
            type: .error
        )
        .onChange(of: editViewModel.errorMessage) { newValue in
            if newValue != nil {
                showToast = true
            }
        }
    }
    
    // MARK: - Sub Views
    
    private var customerSection: some View {
        Section("timesheetEdit.section.customer".localized()) {
            if editViewModel.isLoadingCustomers {
                loadingRow(text: "timesheetEdit.loading.customers".localized())
            } else {
                customerPicker
            }
        }
    }
    
    private var customerPicker: some View {
        Picker("timesheetEdit.picker.customer".localized(), selection: $selectedCustomerId) {
            Text("timesheetEdit.picker.placeholder".localized()).tag(nil as Int?)
            ForEach(editViewModel.customers) { customer in
                Text(customer.name).tag(customer.id as Int?)
            }
        }
        .onChange(of: selectedCustomerId) { newValue in
            guard !isInitializing else { return }
            Task {
                if let customerId = newValue,
                   let customer = editViewModel.customers.first(where: { $0.id == customerId }) {
                    await editViewModel.loadProjects(for: customer)
                }
                selectedProjectId = nil
                selectedActivityId = nil
            }
        }
    }
    
    private var projectSection: some View {
        Section("timesheetEdit.section.project".localized()) {
            if editViewModel.isLoadingProjects {
                loadingRow(text: "timesheetEdit.loading.projects".localized())
            } else {
                projectPicker
            }
        }
    }
    
    private var projectPicker: some View {
        Picker("timesheetEdit.picker.project".localized(), selection: $selectedProjectId) {
            Text("timesheetEdit.picker.placeholder".localized()).tag(nil as Int?)
            ForEach(editViewModel.projects) { project in
                Text(project.name).tag(project.id as Int?)
            }
        }
        .onChange(of: selectedProjectId) { newValue in
            guard !isInitializing else { return }
            Task {
                if let projectId = newValue,
                   let project = editViewModel.projects.first(where: { $0.id == projectId }) {
                    await editViewModel.loadActivities(for: project)
                }
                selectedActivityId = nil
            }
        }
    }
    
    private var activitySection: some View {
        Section("timesheetEdit.section.activity".localized()) {
            if editViewModel.isLoadingActivities {
                loadingRow(text: "timesheetEdit.loading.activities".localized())
            } else {
                activityPicker
            }
        }
    }
    
    private var activityPicker: some View {
        Picker("timesheetEdit.picker.activity".localized(), selection: $selectedActivityId) {
            Text("timesheetEdit.picker.placeholder".localized()).tag(nil as Int?)
            ForEach(editViewModel.activities) { activity in
                Text(activity.name).tag(activity.id as Int?)
            }
        }
    }
    
    private var timeSection: some View {
        Section("timesheetEdit.section.time".localized()) {
            DatePicker("Start", selection: $startDate)
                .onChange(of: startDate) { newStartDate in
                    guard !isAdjustingDates else { return }
                    
                    // Wenn Start nach Ende liegt, setze Ende auf Start + 1 Stunde
                    if newStartDate >= endDate {
                        isAdjustingDates = true
                        endDate = newStartDate.addingTimeInterval(3600)
                        isAdjustingDates = false
                    }
                }
            
            DatePicker("Ende", selection: $endDate)
                .onChange(of: endDate) { newEndDate in
                    guard !isAdjustingDates else { return }
                    
                    // Wenn Ende vor Start liegt, setze Start auf Ende - 1 Stunde
                    if newEndDate <= startDate {
                        isAdjustingDates = true
                        startDate = newEndDate.addingTimeInterval(-3600)
                        isAdjustingDates = false
                    }
                }
        }
    }
    
    private var descriptionSection: some View {
        Section("timesheetEdit.section.description".localized()) {
            TextEditor(text: $descriptionText)
                .frame(minHeight: 100)
        }
    }
    
    private var tagsSection: some View {
        Section("timesheetEdit.section.tags".localized()) {
            TagInputView(
                tags: $tags,
                knownTags: editViewModel.knownTags,
                placeholder: "timesheetEdit.placeholder.tags".localized(),
                onCreateTag: { tagName in
                    try await createTag(tagName)
                },
                onRemoveTag: { tagName in
                    await deleteTagIfCreated(tagName)
                },
                onSearchTags: { searchTerm in
                    await editViewModel.loadTagsForSearch(searchTerm)
                }
            )
        }
    }
    
    private var advancedSettingsSection: some View {
        Section(isExpanded: $showAdvancedSettings) {
            // Fixed Rate
            HStack {
                Text("timesheetEdit.field.fixedRate".localized())
                Spacer()
                TextField("0.00", text: $fixedRate)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
            }
            
            // Hourly Rate
            HStack {
                Text("timesheetEdit.field.hourlyRate".localized())
                Spacer()
                TextField("0.00", text: $hourlyRate)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
            }
            
            // Billable
            Toggle("timesheetEdit.field.billable".localized(), isOn: $billable)
        } header: {
            Text("timesheetEdit.section.advancedSettings".localized())
        }
    }
    
    private func loadingRow(text: String) -> some View {
        HStack {
            ProgressView()
            Text(text)
                .foregroundColor(.timaiGrayTone2)
        }
    }
    
    // MARK: - Helpers
    
    private var canSave: Bool {
        selectedProjectId != nil && selectedActivityId != nil && endDate > startDate
    }
    
    private func saveTimesheet() async {
        guard let projectId = selectedProjectId,
              let activityId = selectedActivityId else {
            return
        }
        
        // Convert string values to Double if not empty
        let fixedRateValue = fixedRate.isEmpty ? nil : Double(fixedRate.replacingOccurrences(of: ",", with: "."))
        let hourlyRateValue = hourlyRate.isEmpty ? nil : Double(hourlyRate.replacingOccurrences(of: ",", with: "."))
        
        let success: Bool
        
        switch mode {
        case .create:
            success = await editViewModel.createTimesheet(
                projectId: projectId,
                activityId: activityId,
                startDate: startDate,
                endDate: endDate,
                description: descriptionText.isEmpty ? nil : descriptionText,
                tags: tags,
                fixedRate: fixedRateValue,
                hourlyRate: hourlyRateValue,
                billable: billable
            )
        case .edit(let existingActivity):
            success = await editViewModel.updateTimesheet(
                id: existingActivity.recordId,
                projectId: projectId,
                activityId: activityId,
                startDate: startDate,
                endDate: endDate,
                description: descriptionText.isEmpty ? nil : descriptionText,
                tags: tags,
                fixedRate: fixedRateValue,
                hourlyRate: hourlyRateValue,
                billable: billable
            )
        }
        
        if success {
            hasBeenSaved = true
            // Cleanup: Lösche Tags, die erstellt aber nicht verwendet wurden
            await cleanupUnusedTags()
            onSaved()
        }
    }
    
    // MARK: - Tag Management
    
    private func createTag(_ tagName: String) async throws {
        guard let user = authViewModel.currentUser else {
            throw NSError(domain: "TimesheetEditView", code: 1, userInfo: [NSLocalizedDescriptionKey: "Kein Benutzer angemeldet"])
        }
        
        // Prüfe Netzwerkverbindung
        guard NetworkMonitor.shared.isConnected else {
            // Im Offline-Fall: Tag wird einfach verwendet, Erstellung erfolgt später beim Sync
            // Füge Tag zu knownTags hinzu, damit er als Vorschlag erscheint
            if !editViewModel.knownTags.contains(where: { $0.caseInsensitiveCompare(tagName) == .orderedSame }) {
                editViewModel.knownTags.append(tagName)
                editViewModel.knownTags.sort { $0.lowercased() < $1.lowercased() }
            }
            // Im Offline-Fall: kein Fehler werfen, Tag kann verwendet werden
            return
        }
        
        // Prüfe, ob Tag bereits existiert
        do {
            if let _ = try await NetworkService.shared.findTagByName(tagName, user: user) {
                return
            }
        } catch let error as NetworkService.APIError {
            // Bei Netzwerkfehler: Tag trotzdem verwenden (wird beim Sync erstellt)
            if case .requestError = error {
                if !editViewModel.knownTags.contains(where: { $0.caseInsensitiveCompare(tagName) == .orderedSame }) {
                    editViewModel.knownTags.append(tagName)
                    editViewModel.knownTags.sort { $0.lowercased() < $1.lowercased() }
                }
                return
            }
            // Bei anderen API-Fehlern: Fehler weiterwerfen
            throw error
        } catch {
            // Bei unbekannten Fehlern: Tag trotzdem verwenden (wird beim Sync erstellt)
            if !editViewModel.knownTags.contains(where: { $0.caseInsensitiveCompare(tagName) == .orderedSame }) {
                editViewModel.knownTags.append(tagName)
                editViewModel.knownTags.sort { $0.lowercased() < $1.lowercased() }
            }
            return
        }
        
        // Erstelle neuen Tag (nur online)
        do {
            let tag = try await NetworkService.shared.createTag(name: tagName, user: user)
            createdTagIds[tagName.lowercased()] = tag.id
            
            // Aktualisiere bekannte Tags
            await editViewModel.loadKnownTags()
        } catch let error as NetworkService.APIError {
            // Bei Netzwerkfehler: Tag trotzdem verwenden (wird beim Sync erstellt)
            if case .requestError = error {
                if !editViewModel.knownTags.contains(where: { $0.caseInsensitiveCompare(tagName) == .orderedSame }) {
                    editViewModel.knownTags.append(tagName)
                    editViewModel.knownTags.sort { $0.lowercased() < $1.lowercased() }
                }
                return
            }
            // Bei anderen API-Fehlern: Fehler weiterwerfen
            throw error
        } catch {
            // Bei unbekannten Fehlern: Tag trotzdem verwenden (wird beim Sync erstellt)
            if !editViewModel.knownTags.contains(where: { $0.caseInsensitiveCompare(tagName) == .orderedSame }) {
                editViewModel.knownTags.append(tagName)
                editViewModel.knownTags.sort { $0.lowercased() < $1.lowercased() }
            }
            return
        }
    }
    
    private func deleteTagIfCreated(_ tagName: String) async {
        // Diese Funktion wird aufgerufen, wenn ein Tag entfernt wird
        // Das Cleanup wird in cleanupUnusedTags() gemacht, nicht hier
    }
    
    private func cleanupUnusedTags() async {
        guard let user = authViewModel.currentUser else { return }
        
        // Prüfe Netzwerkverbindung - Cleanup nur online
        guard NetworkMonitor.shared.isConnected else {
            return
        }
        
        // Finde Tags, die erstellt wurden aber nicht in der finalen Liste sind
        let finalTags = Set(tags.map { $0.lowercased() })
        let tagsToDelete = createdTagIds.filter { !finalTags.contains($0.key) }
        
        for (tagName, tagId) in tagsToDelete {
            do {
                try await NetworkService.shared.deleteTag(id: tagId, user: user)
                createdTagIds.removeValue(forKey: tagName)
            } catch {
                // Fehler beim Löschen ist nicht kritisch
            }
        }
        
        // Aktualisiere bekannte Tags (nur online)
        await editViewModel.loadKnownTags()
    }
}

// MARK: - Edit ViewModel
@MainActor
class TimesheetEditViewModel: ObservableObject {
    @Published var customers: [Customer] = []
    @Published var projects: [Project] = []
    @Published var activities: [ActivityDetails] = []
    @Published var isLoadingCustomers = false
    @Published var isLoadingProjects = false
    @Published var isLoadingActivities = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var knownTags: [String] = []
    
    private let networkService = NetworkService.shared
    private var currentUser: User?
    
    func setUser(_ user: User) {
        self.currentUser = user
    }

    /// Lädt bekannte Tags aus der Kimai API (/api/tags/find) mit Fallback auf Cache/Timesheets
    func loadKnownTags() async {
        guard let user = currentUser else { return }
        
        // WICHTIG: Die Tags-API listet nur explizit erstellte Tags, nicht alle in Timesheets verwendeten
        // Deshalb extrahieren wir Tags immer aus den Timesheets als Basis
        
        // Lade Tags aus Timesheets (Hauptquelle für Vorschläge)
        do {
            let timesheets = try await CacheManager.shared.load([Timesheet].self, for: user, cacheType: .timesheets)
            let allTags = timesheets.flatMap { $0.tags }
            
            var seen = Set<String>()
            var unique: [String] = []
            
            for tag in allTags {
                let key = tag.lowercased()
                if !seen.contains(key) {
                    seen.insert(key)
                    unique.append(tag)
                }
            }
            
            knownTags = unique.sorted { $0.lowercased() < $1.lowercased() }
        } catch {
            knownTags = []
        }
        
        // Versuche zusätzlich Tags von der API zu laden (optional, für explizit erstellte Tags)
        do {
            let tags = try await networkService.getTags(user: user)
            let apiTags = tags.map { $0.name }
            
            if !apiTags.isEmpty {
                // Kombiniere API-Tags mit Timesheet-Tags (keine Duplikate)
                let existingTagNames = Set(knownTags.map { $0.lowercased() })
                let newApiTags = apiTags.filter { !existingTagNames.contains($0.lowercased()) }
                
                knownTags.append(contentsOf: newApiTags)
                knownTags = knownTags.sorted { $0.lowercased() < $1.lowercased() }
            }
        } catch {
            // Fehler beim Laden von API-Tags ist nicht kritisch
        }
    }
    
    /// Lädt Tags dynamisch basierend auf Suchbegriff (API benötigt mindestens 2 Zeichen)
    func loadTagsForSearch(_ searchTerm: String) async -> [String] {
        guard let user = currentUser else { return [] }
        guard searchTerm.count >= 2 else {
            // Bei weniger als 2 Zeichen: nur lokale Tags verwenden
            return knownTags.filter { $0.localizedCaseInsensitiveContains(searchTerm) }
        }
        
        // Prüfe Netzwerkverbindung
        guard NetworkMonitor.shared.isConnected else {
            // Offline: nur lokale Tags verwenden
            return knownTags.filter { $0.localizedCaseInsensitiveContains(searchTerm) }
        }
        
        // Bei 2+ Zeichen: API abfragen (nur online)
        do {
            let tags = try await networkService.getTags(user: user, searchTerm: searchTerm)
            let apiTagNames = tags.map { $0.name }
            
            // Kombiniere mit lokalen Tags
            let localMatches = knownTags.filter { $0.localizedCaseInsensitiveContains(searchTerm) }
            let apiMatches = apiTagNames.filter { $0.localizedCaseInsensitiveContains(searchTerm) }
            
            // Kombiniere und entferne Duplikate
            var combined = Set<String>()
            for tag in localMatches {
                combined.insert(tag)
            }
            for tag in apiMatches {
                combined.insert(tag)
            }
            
            return Array(combined).sorted { $0.lowercased() < $1.lowercased() }
        } catch {
            // Bei Fehler: nur lokale Tags verwenden
            return knownTags.filter { $0.localizedCaseInsensitiveContains(searchTerm) }
        }
    }
    
    /// Find customer ID for a given project by searching all cached projects
    func findCustomerIdForProject(_ projectId: Int) async -> Int {
        guard let user = currentUser else { return 0 }
        
        // Load all customers first
        do {
            let cachedCustomers = try await networkService.getCustomers(user: user)
            
            // Search through all customer project caches
            for customer in cachedCustomers {
                if let projects = try? await CacheManager.shared.load([Project].self, for: user, cacheType: .projectsForCustomer, identifier: "\(customer.id)") {
                    if projects.contains(where: { $0.id == projectId }) {
                        return customer.id
                    }
                }
            }
        } catch {
            // Customer not found
        }
        
        return 0
    }
    
    func loadCustomers() async {
        guard let user = currentUser else { return }
        
        isLoadingCustomers = true
        errorMessage = nil
        
        do {
            customers = try await networkService.getCustomers(user: user)
        } catch {
            // Check if it's offline/no cache error
            if let apiError = error as? NetworkService.APIError,
               case .offlineNoCache = apiError {
                errorMessage = "Offline - Keine Daten im Cache. Bitte einmal online verbinden."
            } else {
            errorMessage = "timesheetEdit.error.loadingCustomers".localized()
            }
        }
        
        isLoadingCustomers = false
    }
    
    func loadAndPreselect(customerId: Int, projectId: Int, activityId: Int) async -> (Customer?, Project?, ActivityDetails?) {
        guard let user = currentUser else { 
            return (nil, nil, nil)
        }
        
        // Ensure customers are loaded
        if customers.isEmpty {
            await loadCustomers()
        }
        
        // Find customer by ID in loaded list
        var customer = customers.first(where: { $0.id == customerId })
        
        // If customer not found, try to load directly from cache/API
        if customer == nil {
            do {
                let allCustomers = try await networkService.getCustomers(user: user)
                customer = allCustomers.first(where: { $0.id == customerId })
                if let foundCustomer = customer {
                    // Update customers list if not already there
                    if !customers.contains(where: { $0.id == foundCustomer.id }) {
                        customers.append(foundCustomer)
                    }
                } else {
                    return (nil, nil, nil)
                }
            } catch {
                return (nil, nil, nil)
            }
        }
        
        guard let customer = customer else {
            return (nil, nil, nil)
        }
        
        // Load projects for this customer
        await loadProjects(for: customer)
        
        // Find project by ID
        guard let project = projects.first(where: { $0.id == projectId }) else {
            return (customer, nil, nil)
        }
        
        // Load activities for this project
        await loadActivities(for: project)
        
        // Find activity by ID
        let activity = activities.first(where: { $0.id == activityId })
        
        return (customer, project, activity)
    }
    
    func loadProjects(for customer: Customer) async {
        guard let user = currentUser else { return }
        
        isLoadingProjects = true
        projects = []
        errorMessage = nil
        
        do {
            projects = try await networkService.getProjects(customer: customer, user: user)
        } catch {
            errorMessage = "timesheetEdit.error.loadingProjects".localized()
        }
        
        isLoadingProjects = false
    }
    
    func loadActivities(for project: Project) async {
        guard let user = currentUser else { return }
        
        isLoadingActivities = true
        activities = []
        errorMessage = nil
        
        do {
            activities = try await networkService.getActivities(projectId: project.id, user: user)
        } catch {
            errorMessage = "timesheetEdit.error.loadingActivities".localized()
        }
        
        isLoadingActivities = false
    }
    
    func createTimesheet(projectId: Int, activityId: Int, startDate: Date, endDate: Date, description: String?, tags: [String], fixedRate: Double?, hourlyRate: Double?, billable: Bool) async -> Bool {
        guard let user = currentUser else { return false }
        
        isSaving = true
        errorMessage = nil
        
        let tagsString = TagUtils.string(from: tags)
        
        let form = TimesheetEditForm(
            project: projectId,
            activity: activityId,
            begin: startDate.ISO8601Format(),
            end: endDate.ISO8601Format(),
            description: description,
            tags: tagsString,
            fixedRate: fixedRate,
            hourlyRate: hourlyRate,
            user: nil,
            exported: nil,
            billable: billable
        )
        
        do {
            _ = try await networkService.createTimesheet(form: form, user: user)
            await loadKnownTags()
            isSaving = false
            return true
        } catch {
            errorMessage = "timesheetEdit.error.saving".localized()
            isSaving = false
            return false
        }
    }
    
    func updateTimesheet(id: Int, projectId: Int, activityId: Int, startDate: Date, endDate: Date, description: String?, tags: [String], fixedRate: Double?, hourlyRate: Double?, billable: Bool) async -> Bool {
        guard let user = currentUser else { return false }
        
        isSaving = true
        errorMessage = nil
        
        let tagsString = TagUtils.string(from: tags)
        
        let form = TimesheetEditForm(
            project: projectId,
            activity: activityId,
            begin: startDate.ISO8601Format(),
            end: endDate.ISO8601Format(),
            description: description,
            tags: tagsString,
            fixedRate: fixedRate,
            hourlyRate: hourlyRate,
            user: nil,
            exported: nil,
            billable: billable
        )
        
        do {
            _ = try await networkService.updateTimesheet(id: id, form: form, user: user)
            await loadKnownTags()
            isSaving = false
            return true
        } catch {
            errorMessage = "timesheetEdit.error.saving".localized()
            isSaving = false
            return false
        }
    }
}

#Preview {
    NavigationStack {
        TimesheetEditView(mode: .create, onSaved: {})
            .environmentObject(AuthViewModel())
    }
}
