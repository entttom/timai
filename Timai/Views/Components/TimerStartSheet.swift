//
//  TimerStartSheet.swift
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
import Combine

/// Sheet for starting a new timer
struct TimerStartSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = TimerStartViewModel()
    
    let onTimerStarted: () -> Void
    
    @State private var selectedCustomerId: Int?
    @State private var selectedProjectId: Int?
    @State private var selectedActivityId: Int?
    @State private var descriptionText = ""
    @State private var isStarting = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Customer Section
                Section("timesheetEdit.section.customer".localized()) {
                    if viewModel.isLoadingCustomers {
                        loadingRow(text: "timesheetEdit.loading.customers".localized())
                    } else {
                        Picker("timesheetEdit.picker.customer".localized(), selection: $selectedCustomerId) {
                            Text("timesheetEdit.picker.placeholder".localized()).tag(nil as Int?)
                            ForEach(viewModel.customers) { customer in
                                Text(customer.name).tag(customer.id as Int?)
                            }
                        }
                        .onChange(of: selectedCustomerId) { newValue in
                            Task {
                                if let customerId = newValue,
                                   let customer = viewModel.customers.first(where: { $0.id == customerId }) {
                                    await viewModel.loadProjects(for: customer)
                                }
                                selectedProjectId = nil
                                selectedActivityId = nil
                            }
                        }
                    }
                }
                
                // Project Section
                if selectedCustomerId != nil {
                    Section("timesheetEdit.section.project".localized()) {
                        if viewModel.isLoadingProjects {
                            loadingRow(text: "timesheetEdit.loading.projects".localized())
                        } else {
                            Picker("timesheetEdit.picker.project".localized(), selection: $selectedProjectId) {
                                Text("timesheetEdit.picker.placeholder".localized()).tag(nil as Int?)
                                ForEach(viewModel.projects) { project in
                                    Text(project.name).tag(project.id as Int?)
                                }
                            }
                            .onChange(of: selectedProjectId) { newValue in
                                Task {
                                    if let projectId = newValue,
                                       let project = viewModel.projects.first(where: { $0.id == projectId }) {
                                        await viewModel.loadActivities(for: project)
                                    }
                                    selectedActivityId = nil
                                }
                            }
                        }
                    }
                }
                
                // Activity Section
                if selectedProjectId != nil {
                    Section("timesheetEdit.section.activity".localized()) {
                        if viewModel.isLoadingActivities {
                            loadingRow(text: "timesheetEdit.loading.activities".localized())
                        } else {
                            Picker("timesheetEdit.picker.activity".localized(), selection: $selectedActivityId) {
                                Text("timesheetEdit.picker.placeholder".localized()).tag(nil as Int?)
                                ForEach(viewModel.activities) { activity in
                                    Text(activity.name).tag(activity.id as Int?)
                                }
                            }
                        }
                    }
                }
                
                // Description Section
                if selectedActivityId != nil {
                    Section("timesheetEdit.section.description".localized()) {
                        TextField("timer.description.placeholder".localized(), text: $descriptionText, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }
            }
            .navigationTitle("timer.start.title".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("timesheetEdit.button.cancel".localized()) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("timer.start.button".localized()) {
                        Task {
                            await startTimer()
                        }
                    }
                    .disabled(!canStart || isStarting)
                    .bold()
                }
            }
            .task {
                if let user = authViewModel.currentUser {
                    viewModel.setUser(user)
                    await viewModel.loadCustomers()
                }
            }
            .overlay {
                if isStarting {
                    LoadingOverlay()
                }
            }
        }
    }
    
    private func loadingRow(text: String) -> some View {
        HStack {
            ProgressView()
            Text(text)
                .foregroundColor(.timaiGrayTone2)
        }
    }
    
    private var canStart: Bool {
        selectedProjectId != nil && selectedActivityId != nil
    }
    
    private func startTimer() async {
        guard let user = authViewModel.currentUser,
              let projectId = selectedProjectId,
              let activityId = selectedActivityId,
              let project = viewModel.projects.first(where: { $0.id == projectId }),
              let activity = viewModel.activities.first(where: { $0.id == activityId }),
              let customer = viewModel.customers.first(where: { $0.id == project.customer.id })
        else {
            return
        }
        
        isStarting = true
        
        do {
            try await TimerManager.shared.startTimer(
                projectId: projectId,
                projectName: project.name,
                activityId: activityId,
                activityName: activity.name,
                customerId: customer.id,
                customerName: customer.name,
                description: descriptionText.isEmpty ? nil : descriptionText,
                user: user
            )
            
            dismiss()
            onTimerStarted()
        } catch {
            print("❌ [TimerStartSheet] Fehler beim Starten des Timers: \(error)")
            // TODO: Show error to user
        }
        
        isStarting = false
    }
}

// MARK: - ViewModel
@MainActor
class TimerStartViewModel: ObservableObject {
    @Published var customers: [Customer] = []
    @Published var projects: [Project] = []
    @Published var activities: [ActivityDetails] = []
    @Published var isLoadingCustomers = false
    @Published var isLoadingProjects = false
    @Published var isLoadingActivities = false
    
    private let networkService = NetworkService.shared
    private var currentUser: User?
    
    func setUser(_ user: User) {
        self.currentUser = user
    }
    
    func loadCustomers() async {
        guard let user = currentUser else { return }
        
        isLoadingCustomers = true
        
        do {
            customers = try await networkService.getCustomers(user: user)
        } catch {
            print("❌ [TimerStartViewModel] Fehler beim Laden der Kunden: \(error)")
        }
        
        isLoadingCustomers = false
    }
    
    func loadProjects(for customer: Customer) async {
        guard let user = currentUser else { return }
        
        isLoadingProjects = true
        projects = []
        
        do {
            projects = try await networkService.getProjects(customer: customer, user: user)
        } catch {
            print("❌ [TimerStartViewModel] Fehler beim Laden der Projekte: \(error)")
        }
        
        isLoadingProjects = false
    }
    
    func loadActivities(for project: Project) async {
        guard let user = currentUser else { return }
        
        isLoadingActivities = true
        activities = []
        
        do {
            activities = try await networkService.getActivities(projectId: project.id, user: user)
        } catch {
            print("❌ [TimerStartViewModel] Fehler beim Laden der Aktivitäten: \(error)")
        }
        
        isLoadingActivities = false
    }
}

#Preview {
    TimerStartSheet(onTimerStarted: {})
        .environmentObject(AuthViewModel())
}

