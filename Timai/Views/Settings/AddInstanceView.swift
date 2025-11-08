//
//  AddInstanceView.swift
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

struct AddInstanceView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var instanceName: String = ""
    @State private var kimaiURL: String = ""
    @State private var apiToken: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, url, token
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("addInstance.name.placeholder".localized(), text: $instanceName)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .url }
                } header: {
                    Text("addInstance.section.name".localized())
                } footer: {
                    Text("addInstance.section.name.footer".localized())
                }
                
                Section {
                    TextField("addInstance.url.placeholder".localized(), text: $kimaiURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .url)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .token }
                } header: {
                    Text("addInstance.section.url".localized())
                } footer: {
                    Text("addInstance.section.url.footer".localized())
                }
                
                Section {
                    SecureField("addInstance.token.placeholder".localized(), text: $apiToken)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .token)
                        .submitLabel(.done)
                        .onSubmit { addInstance() }
                } header: {
                    Text("addInstance.section.token".localized())
                } footer: {
                    Text("addInstance.section.token.footer".localized())
                }
            }
            .navigationTitle("addInstance.title".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("addInstance.button.cancel".localized()) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("addInstance.button.add".localized()) {
                        addInstance()
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
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    }
                }
            }
            .alert("addInstance.error.title".localized(), isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "addInstance.error.unknown".localized())
            }
        }
    }
    
    private func addInstance() {
        guard let url = URL(string: kimaiURL) else {
            errorMessage = "addInstance.error.invalidURL".localized()
            showError = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            await authViewModel.login(kimaiURL: url, apiToken: apiToken, instanceName: instanceName)
            
            isLoading = false
            
            // Check if login was successful
            if authViewModel.errorMessage == nil {
                // Success - dismiss view
                dismiss()
            } else {
                // Show error
                errorMessage = authViewModel.errorMessage
                showError = true
            }
        }
    }
}

#Preview {
    AddInstanceView()
        .environmentObject(AuthViewModel())
}


