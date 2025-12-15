//
//  EditInstanceView.swift
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

struct EditInstanceView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var instanceManager: InstanceManager
    
    let instance: KimaiInstance
    
    @State private var instanceName: String
    @State private var kimaiURL: String
    @State private var apiToken: String
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showSuccess = false
    @State private var showDeleteAlert = false
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, url, token
    }
    
    init(instance: KimaiInstance) {
        self.instance = instance
        _instanceName = State(initialValue: instance.name)
        _kimaiURL = State(initialValue: instance.apiEndpoint.absoluteString)
        _apiToken = State(initialValue: instance.apiToken ?? "")
    }
    
    var body: some View {
        Form {
            Section {
                TextField("editInstance.name.placeholder".localized(), text: $instanceName)
                    .focused($focusedField, equals: .name)
                    #if os(iOS)
                    .submitLabel(.next)
                    #endif
                    .onSubmit { focusedField = .url }
            } header: {
                Text("editInstance.section.name".localized())
            } footer: {
                Text("editInstance.section.name.footer".localized())
            }
            
            Section {
                TextField("editInstance.url.placeholder".localized(), text: $kimaiURL)
                    #if os(iOS)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    #endif
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .url)
                    #if os(iOS)
                    .submitLabel(.next)
                    #endif
                    .onSubmit { focusedField = .token }
            } header: {
                Text("editInstance.section.url".localized())
            } footer: {
                Text("editInstance.section.url.footer".localized())
            }
            
            Section {
                SecureField("editInstance.token.placeholder".localized(), text: $apiToken)
                    #if os(iOS)
                    .autocapitalization(.none)
                    #endif
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .token)
                    #if os(iOS)
                    .submitLabel(.done)
                    #endif
                    .onSubmit { saveChanges() }
            } header: {
                Text("editInstance.section.token".localized())
            } footer: {
                Text("editInstance.section.token.footer".localized())
            }
            
            // Delete Section
            Section {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    HStack {
                        Spacer()
                        Label("editInstance.button.delete".localized(), systemImage: "trash")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("editInstance.title".localized())
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("editInstance.button.save".localized()) {
                    saveChanges()
                }
                .disabled(instanceName.isEmpty || kimaiURL.isEmpty || apiToken.isEmpty || isLoading)
            }
        }
        .disabled(isLoading)
        .overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("editInstance.verifying".localized())
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                }
            }
        }
        .alert("editInstance.error.title".localized(), isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "editInstance.error.unknown".localized())
        }
        .alert("editInstance.success.title".localized(), isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("editInstance.success.message".localized())
        }
        .alert("editInstance.delete.title".localized(), isPresented: $showDeleteAlert) {
            Button("editInstance.delete.cancel".localized(), role: .cancel) {}
            Button("editInstance.delete.confirm".localized(), role: .destructive) {
                deleteInstance()
            }
        } message: {
            Text(String(format: "editInstance.delete.message".localized(), instance.name))
        }
    }
    
    private func deleteInstance() {
        Task {
            do {
                try await instanceManager.deleteInstance(instance)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func saveChanges() {
        // Trim Whitespace am Anfang/Ende der Eingaben
        let trimmedURLString = kimaiURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedToken = apiToken.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let url = URL(string: trimmedURLString) else {
            errorMessage = "editInstance.error.invalidURL".localized()
            showError = true
            return
        }
        
        // Aktualisiere Felder im UI mit getrimmten Werten
        if trimmedURLString != kimaiURL {
            kimaiURL = trimmedURLString
        }
        if trimmedToken != apiToken {
            apiToken = trimmedToken
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            // Verify connection with new credentials
            do {
                // Prüfe ob URL bereits mit /api endet
                let api: URL
                if url.absoluteString.hasSuffix("/api") || url.absoluteString.hasSuffix("/api/") {
                    api = url
                } else {
                    api = url.appendingPathComponent("api")
                }
                
                let tempUser = User(apiEndpoint: api, apiToken: trimmedToken)
                let _ = try await NetworkService.shared.checkVersion(for: api, with: tempUser)
                
                // Verification successful - update instance
                var updatedInstance = instance
                updatedInstance.name = instanceName
                
                // Save new token
                try updatedInstance.saveToken(trimmedToken)
                
                // If URL changed, we need to create a new instance
                if api != instance.apiEndpoint {
                    // Delete old instance
                    try await instanceManager.deleteInstance(instance)
                    
                    // Create new instance with new URL
                    let newInstance = KimaiInstance(
                        name: instanceName,
                        apiEndpoint: api,
                        isActive: instance.isActive
                    )
                    try newInstance.saveToken(trimmedToken)
                    instanceManager.addInstance(newInstance)
                    
                    // If it was active, switch to it
                    if instance.isActive {
                        instanceManager.switchToInstance(newInstance)
                        
                        // Update AuthViewModel
                        authViewModel.currentUser = User(
                            apiEndpoint: api,
                            apiToken: trimmedToken,
                            instanceId: newInstance.id
                        )
                    }
                } else {
                    // Only name or token changed
                    instanceManager.updateInstance(updatedInstance)
                    
                    // If it was active, update AuthViewModel
                    if instance.isActive {
                        authViewModel.currentUser = User(
                            apiEndpoint: api,
                            apiToken: trimmedToken,
                            instanceId: updatedInstance.id
                        )
                    }
                }
                
                isLoading = false
                showSuccess = true
                
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        EditInstanceView(instance: KimaiInstance(
            name: "Test Instance",
            apiEndpoint: URL(string: "https://demo.kimai.org/api")!,
            isActive: true
        ))
        .environmentObject(AuthViewModel())
        .environmentObject(InstanceManager.shared)
    }
}

