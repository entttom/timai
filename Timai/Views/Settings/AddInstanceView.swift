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
                        #if os(iOS)
                        .submitLabel(.next)
                        #endif
                        .onSubmit { focusedField = .url }
                } header: {
                    Text("addInstance.section.name".localized())
                } footer: {
                    Text("addInstance.section.name.footer".localized())
                }
                
                Section {
                    TextField("addInstance.url.placeholder".localized(), text: $kimaiURL)
                        #if os(iOS)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .submitLabel(.next)
                        #endif
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .url)
                        .onSubmit { focusedField = .token }
                } header: {
                    Text("addInstance.section.url".localized())
                } footer: {
                    Text("addInstance.section.url.footer".localized())
                }
                
                Section {
                    SecureField("addInstance.token.placeholder".localized(), text: $apiToken)
                        #if os(iOS)
                        .autocapitalization(.none)
                        .submitLabel(.done)
                        #endif
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .token)
                        .onSubmit { addInstance() }
                } header: {
                    Text("addInstance.section.token".localized())
                } footer: {
                    Text("addInstance.section.token.footer".localized())
                }
            }
            .navigationTitle("addInstance.title".localized())
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
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
        // Trim Whitespace am Anfang/Ende der Eingaben
        let trimmedURLString = kimaiURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedToken = apiToken.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let url = URL(string: trimmedURLString) else {
            errorMessage = "addInstance.error.invalidURL".localized()
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
            await authViewModel.login(kimaiURL: url, apiToken: trimmedToken, instanceName: instanceName)
            
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


