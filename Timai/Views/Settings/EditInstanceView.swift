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
                    .submitLabel(.next)
                    .onSubmit { focusedField = .url }
            } header: {
                Text("editInstance.section.name".localized())
            } footer: {
                Text("editInstance.section.name.footer".localized())
            }
            
            Section {
                TextField("editInstance.url.placeholder".localized(), text: $kimaiURL)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .url)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .token }
            } header: {
                Text("editInstance.section.url".localized())
            } footer: {
                Text("editInstance.section.url.footer".localized())
            }
            
            Section {
                SecureField("editInstance.token.placeholder".localized(), text: $apiToken)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .token)
                    .submitLabel(.done)
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
        .navigationBarTitleDisplayMode(.inline)
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
        guard let url = URL(string: kimaiURL) else {
            errorMessage = "editInstance.error.invalidURL".localized()
            showError = true
            return
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
                
                let tempUser = User(apiEndpoint: api, apiToken: apiToken)
                let _ = try await NetworkService.shared.checkVersion(for: api, with: tempUser)
                
                // Verification successful - update instance
                var updatedInstance = instance
                updatedInstance.name = instanceName
                
                // Save new token
                try updatedInstance.saveToken(apiToken)
                
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
                    try newInstance.saveToken(apiToken)
                    instanceManager.addInstance(newInstance)
                    
                    // If it was active, switch to it
                    if instance.isActive {
                        instanceManager.switchToInstance(newInstance)
                        
                        // Update AuthViewModel
                        authViewModel.currentUser = User(
                            apiEndpoint: api,
                            apiToken: apiToken,
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
                            apiToken: apiToken,
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

