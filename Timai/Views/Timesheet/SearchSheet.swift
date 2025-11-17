//
//  SearchSheet.swift
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

struct SearchSheet: View {
    @Binding var searchText: String
    @Binding var searchFilters: SearchFilters
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var searchViewModel = SearchViewModel()
    
    @State private var localSearchText: String = ""
    @State private var localFilters: SearchFilters = SearchFilters()
    
    var body: some View {
        NavigationStack {
            Form {
                // Textsuche
                Section {
                    TextField("search.placeholder".localized(), text: $localSearchText)
                        .textInputAutocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: localSearchText) { newValue in
                            searchText = newValue
                        }
                }
                
                // Datumsfilter
                Section("search.filters.date".localized()) {
                    Toggle("search.filters.dateFrom".localized(), isOn: Binding(
                        get: { localFilters.dateFrom != nil },
                        set: { isOn in
                            if isOn {
                                localFilters.dateFrom = localFilters.dateFrom ?? Date()
                            } else {
                                localFilters.dateFrom = nil
                            }
                            updateFilters()
                        }
                    ))
                    
                    if localFilters.dateFrom != nil {
                        DatePicker("", selection: Binding(
                            get: { localFilters.dateFrom ?? Date() },
                            set: { newValue in
                                localFilters.dateFrom = newValue
                                updateFilters()
                            }
                        ), displayedComponents: .date)
                    }
                    
                    Toggle("search.filters.dateTo".localized(), isOn: Binding(
                        get: { localFilters.dateTo != nil },
                        set: { isOn in
                            if isOn {
                                localFilters.dateTo = localFilters.dateTo ?? Date()
                            } else {
                                localFilters.dateTo = nil
                            }
                            updateFilters()
                        }
                    ))
                    
                    if localFilters.dateTo != nil {
                        DatePicker("", selection: Binding(
                            get: { localFilters.dateTo ?? Date() },
                            set: { newValue in
                                localFilters.dateTo = newValue
                                updateFilters()
                            }
                        ), displayedComponents: .date)
                    }
                }
                
                // Kundenfilter
                Section("search.filters.customer".localized()) {
                    if searchViewModel.isLoadingCustomers {
                        HStack {
                            ProgressView()
                            Text("timesheetEdit.loading.customers".localized())
                                .foregroundColor(.timaiGrayTone2)
                        }
                    } else {
                        Picker("search.filters.customer".localized(), selection: Binding(
                            get: { localFilters.selectedCustomerId },
                            set: { newValue in
                                localFilters.selectedCustomerId = newValue
                                if newValue == nil {
                                    localFilters.selectedProjectId = nil
                                } else {
                                    Task {
                                        if let customerId = newValue,
                                           let customer = searchViewModel.customers.first(where: { $0.id == customerId }) {
                                            await searchViewModel.loadProjects(for: customer)
                                        }
                                    }
                                }
                                updateFilters()
                            }
                        )) {
                            Text("timesheetEdit.picker.placeholder".localized()).tag(nil as Int?)
                            ForEach(searchViewModel.customers) { customer in
                                Text(customer.name).tag(customer.id as Int?)
                            }
                        }
                    }
                }
                
                // Projektfilter
                if localFilters.selectedCustomerId != nil {
                    Section("search.filters.project".localized()) {
                        if searchViewModel.isLoadingProjects {
                            HStack {
                                ProgressView()
                                Text("timesheetEdit.loading.projects".localized())
                                    .foregroundColor(.timaiGrayTone2)
                            }
                        } else {
                            Picker("search.filters.project".localized(), selection: Binding(
                                get: { localFilters.selectedProjectId },
                                set: { newValue in
                                    localFilters.selectedProjectId = newValue
                                    updateFilters()
                                }
                            )) {
                                Text("timesheetEdit.picker.placeholder".localized()).tag(nil as Int?)
                                ForEach(searchViewModel.projects) { project in
                                    Text(project.name).tag(project.id as Int?)
                                }
                            }
                        }
                    }
                }
                
                // Tag-Filter (Chip-basiert)
                Section("search.filters.tags".localized()) {
                    TagFilterView(
                        selectedTags: Binding(
                            get: { localFilters.selectedTags },
                            set: { newValue in
                                localFilters.selectedTags = newValue
                                updateFilters()
                            }
                        ),
                        knownTags: searchViewModel.knownTags
                    )
                }
            }
            .navigationTitle("search.title".localized())
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("search.filters.reset".localized()) {
                        resetFilters()
                    }
                    .disabled(!localFilters.hasActiveFilters && localSearchText.isEmpty)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("search.filters.done".localized()) {
                        dismiss()
                    }
                }
            }
            .task {
                if let user = authViewModel.currentUser {
                    searchViewModel.setUser(user)
                    await searchViewModel.loadCustomers()
                    await searchViewModel.loadKnownTags()
                }
                
                // Initialisiere lokale Werte
                localSearchText = searchText
                localFilters = searchFilters
            }
        }
    }
    
    private func updateFilters() {
        searchFilters = localFilters
    }
    
    private func resetFilters() {
        localSearchText = ""
        localFilters.reset()
        searchText = ""
        searchFilters.reset()
    }
}

// MARK: - Tag Filter View (Chip-basiert)
struct TagFilterView: View {
    @Binding var selectedTags: [String]
    let knownTags: [String]
    
    var body: some View {
        if knownTags.isEmpty {
            Text("search.filters.tags.empty".localized())
                .foregroundColor(.timaiGrayTone2)
                .font(.caption)
        } else {
            FlowLayout(spacing: 8) {
                ForEach(knownTags, id: \.self) { tag in
                    TagFilterChip(
                        tag: tag,
                        isSelected: selectedTags.contains { $0.caseInsensitiveCompare(tag) == .orderedSame },
                        onToggle: {
                            toggleTag(tag)
                        }
                    )
                }
            }
        }
    }
    
    private func toggleTag(_ tag: String) {
        if let index = selectedTags.firstIndex(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }
}

struct TagFilterChip: View {
    let tag: String
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white : .timaiHighlight)
                
                Text(tag)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .white : .timaiTextBlack)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.timaiHighlight : Color.timaiHighlight.opacity(0.12))
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? Color.timaiHighlight : Color.timaiHighlight.opacity(0.25), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Search ViewModel
@MainActor
class SearchViewModel: ObservableObject {
    @Published var customers: [Customer] = []
    @Published var projects: [Project] = []
    @Published var isLoadingCustomers = false
    @Published var isLoadingProjects = false
    @Published var knownTags: [String] = []
    
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
            print("❌ [SearchViewModel] Fehler beim Laden der Kunden: \(error)")
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
            print("❌ [SearchViewModel] Fehler beim Laden der Projekte: \(error)")
        }
        
        isLoadingProjects = false
    }
    
    func loadKnownTags() async {
        guard let user = currentUser else { return }
        
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
        
        // Versuche zusätzlich Tags von der API zu laden (optional)
        do {
            let tags = try await networkService.getTags(user: user)
            let apiTags = tags.map { $0.name }
            
            if !apiTags.isEmpty {
                let existingTagNames = Set(knownTags.map { $0.lowercased() })
                let newApiTags = apiTags.filter { !existingTagNames.contains($0.lowercased()) }
                
                knownTags.append(contentsOf: newApiTags)
                knownTags = knownTags.sorted { $0.lowercased() < $1.lowercased() }
            }
        } catch {
            // Fehler beim Laden von API-Tags ist nicht kritisch
        }
    }
}

#Preview {
    SearchSheet(
        searchText: .constant(""),
        searchFilters: .constant(SearchFilters())
    )
    .environmentObject(AuthViewModel())
}

