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
    @State private var tagsText = ""
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
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("timesheetEdit.button.cancel".localized()) {
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
                    
                    // For offline-created entries, customer ID might be 0
                    // In that case, try to find customer from project cache
                    var effectiveCustomerId = activity.customerId
                    if effectiveCustomerId == 0 {
                        print("⚠️ [TimesheetEditView] Customer ID ist 0 - versuche aus Project-Cache zu laden")
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
                    print("🔍 [Edit] Customer ID gesetzt: \(customer?.id ?? -1) - \(customer?.name ?? "nil")")
                    
                    selectedProjectId = project?.id
                    print("🔍 [Edit] Projekt ID gesetzt: \(project?.id ?? -1) - \(project?.name ?? "nil")")
                    print("🔍 [Edit] Verfügbare Projekte: \(editViewModel.projects.map { "\($0.id): \($0.name)" })")
                    
                    selectedActivityId = activityDetails?.id
                    print("🔍 [Edit] Aktivität ID gesetzt: \(activityDetails?.id ?? -1) - \(activityDetails?.name ?? "nil")")
                    print("🔍 [Edit] Verfügbare Aktivitäten: \(editViewModel.activities.map { "\($0.id): \($0.name)" })")
                    
                    // Kleine Verzögerung für UI-Update
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 Sekunden
                    
                    isInitializing = false
                    print("✅ [Edit] Initialisierung abgeschlossen")
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
                        print("⏰ [TimesheetEditView] Start nach Ende - Endzeit auf +1h gesetzt")
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
                        print("⏰ [TimesheetEditView] Ende vor Start - Startzeit auf -1h gesetzt")
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
            TextField("timesheetEdit.placeholder.tags".localized(), text: $tagsText)
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
                tags: tagsText.isEmpty ? nil : tagsText,
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
                tags: tagsText.isEmpty ? nil : tagsText,
                fixedRate: fixedRateValue,
                hourlyRate: hourlyRateValue,
                billable: billable
            )
        }
        
        if success {
            onSaved()
        }
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
    
    private let networkService = NetworkService.shared
    private var currentUser: User?
    
    func setUser(_ user: User) {
        self.currentUser = user
    }
    
    /// Find customer ID for a given project by searching all cached projects
    func findCustomerIdForProject(_ projectId: Int) async -> Int {
        guard let user = currentUser else { return 0 }
        
        print("🔍 [TimesheetEditViewModel] Suche Customer für Project ID: \(projectId)")
        
        // Load all customers first
        do {
            let cachedCustomers = try await networkService.getCustomers(user: user)
            
            // Search through all customer project caches
            for customer in cachedCustomers {
                if let projects = try? await CacheManager.shared.load([Project].self, for: user, cacheType: .projectsForCustomer, identifier: "\(customer.id)") {
                    if projects.contains(where: { $0.id == projectId }) {
                        print("✅ [TimesheetEditViewModel] Customer gefunden: \(customer.name) (ID: \(customer.id))")
                        return customer.id
                    }
                }
            }
        } catch {
            print("⚠️ [TimesheetEditViewModel] Konnte Customer nicht finden")
        }
        
        return 0
    }
    
    func loadCustomers() async {
        guard let user = currentUser else { return }
        
        isLoadingCustomers = true
        errorMessage = nil
        
        do {
            customers = try await networkService.getCustomers(user: user)
            print("✅ [TimesheetEditViewModel] \(customers.count) Kunden geladen")
        } catch {
            print("❌ [TimesheetEditViewModel] Fehler beim Laden der Kunden: \(error)")
            
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
        
        // Find customer by ID
        guard let customer = customers.first(where: { $0.id == customerId }) else {
            print("⚠️ [TimesheetEditViewModel] Kunde mit ID \(customerId) nicht gefunden")
            return (nil, nil, nil)
        }
        
        // Load projects for this customer
        await loadProjects(for: customer)
        print("✅ [TimesheetEditViewModel] \(projects.count) Projekte für Kunde '\(customer.name)' geladen")
        
        // Find project by ID
        guard let project = projects.first(where: { $0.id == projectId }) else {
            print("⚠️ [TimesheetEditViewModel] Projekt mit ID \(projectId) nicht gefunden")
            return (customer, nil, nil)
        }
        
        // Load activities for this project
        await loadActivities(for: project)
        print("✅ [TimesheetEditViewModel] \(activities.count) Aktivitäten für Projekt '\(project.name)' geladen")
        
        // Find activity by ID
        let activity = activities.first(where: { $0.id == activityId })
        if activity == nil {
            print("⚠️ [TimesheetEditViewModel] Aktivität mit ID \(activityId) nicht gefunden")
        } else {
            print("✅ [TimesheetEditViewModel] Aktivität '\(activity!.name)' gefunden")
        }
        
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
            print("❌ [TimesheetEditViewModel] Fehler beim Laden der Projekte: \(error)")
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
            print("❌ [TimesheetEditViewModel] Fehler beim Laden der Aktivitäten: \(error)")
            errorMessage = "timesheetEdit.error.loadingActivities".localized()
        }
        
        isLoadingActivities = false
    }
    
    func createTimesheet(projectId: Int, activityId: Int, startDate: Date, endDate: Date, description: String?, tags: String?, fixedRate: Double?, hourlyRate: Double?, billable: Bool) async -> Bool {
        guard let user = currentUser else { return false }
        
        isSaving = true
        errorMessage = nil
        
        let form = TimesheetEditForm(
            project: projectId,
            activity: activityId,
            begin: startDate.ISO8601Format(),
            end: endDate.ISO8601Format(),
            description: description,
            tags: tags,
            fixedRate: fixedRate,
            hourlyRate: hourlyRate,
            user: nil,
            exported: nil,
            billable: billable
        )
        
        do {
            _ = try await networkService.createTimesheet(form: form, user: user)
            isSaving = false
            return true
        } catch {
            print("❌ [TimesheetEditViewModel] Fehler beim Erstellen: \(error)")
            errorMessage = "timesheetEdit.error.saving".localized()
            isSaving = false
            return false
        }
    }
    
    func updateTimesheet(id: Int, projectId: Int, activityId: Int, startDate: Date, endDate: Date, description: String?, tags: String?, fixedRate: Double?, hourlyRate: Double?, billable: Bool) async -> Bool {
        guard let user = currentUser else { return false }
        
        isSaving = true
        errorMessage = nil
        
        let form = TimesheetEditForm(
            project: projectId,
            activity: activityId,
            begin: startDate.ISO8601Format(),
            end: endDate.ISO8601Format(),
            description: description,
            tags: tags,
            fixedRate: fixedRate,
            hourlyRate: hourlyRate,
            user: nil,
            exported: nil,
            billable: billable
        )
        
        do {
            _ = try await networkService.updateTimesheet(id: id, form: form, user: user)
            isSaving = false
            return true
        } catch {
            print("❌ [TimesheetEditViewModel] Fehler beim Aktualisieren: \(error)")
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
