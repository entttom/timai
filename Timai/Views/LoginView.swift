//
//  LoginView.swift
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

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var instanceName: String = ""
    @State private var kimaiURL: String = ""
    @State private var apiToken: String = ""
    @State private var showToast = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, url, token
    }
    
    var body: some View {
        ZStack {
            // Background
            LoginBackgroundView()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Logo oben
                Image("LogoWhiteTransparent")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 120)
                    .padding(.top, 80)
                
                Spacer()
                
                // Login Form - vertikal zentriert
                VStack(spacing: 20) {
                    // Instance Name Input
                    HStack(spacing: 15) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 24)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        
                        ZStack(alignment: .leading) {
                            if instanceName.isEmpty {
                                Text("Instanzname (z.B. Firma)")
                                    .foregroundColor(.primary.opacity(0.4))
                            }
                            TextField("", text: $instanceName)
                                #if os(iOS)
                                .autocapitalization(.words)
                                .submitLabel(.next)
                                #endif
                                .focused($focusedField, equals: .name)
                                .tint(.timaiHighlight)
                                .onSubmit {
                                    focusedField = .url
                                }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    )
                    
                    // URL Input
                    HStack(spacing: 15) {
                        Image(systemName: "link")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 24)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        
                        ZStack(alignment: .leading) {
                            if kimaiURL.isEmpty {
                                Text("Kimai Server URL")
                                    .foregroundColor(.primary.opacity(0.4))
                            }
                            TextField("", text: $kimaiURL)
                                #if os(iOS)
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                                .submitLabel(.next)
                                #endif
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .url)
                                .tint(.timaiHighlight)
                                .onSubmit {
                                    focusedField = .token
                                }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    )
                    
                    // API Token Input
                    HStack(spacing: 15) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 24)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        
                        SecureField("API Token", text: $apiToken)
                            #if os(iOS)
                            .autocapitalization(.none)
                            .submitLabel(.go)
                            #endif
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .token)
                            .tint(.timaiHighlight)
                            .onSubmit {
                                performLogin()
                            }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    )
                    
                    // Login Button
                    Button(action: performLogin) {
                        Text("Anmelden")
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(PrimaryButtonStyle(isLoading: authViewModel.isLoading))
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
            
            // Loading Overlay
            if authViewModel.isLoading {
                LoadingOverlay()
            }
        }
        .onChange(of: authViewModel.errorMessage) { newValue in
            if newValue != nil {
                showToast = true
            }
        }
        .toast(
            isShowing: $showToast,
            message: authViewModel.errorMessage ?? "",
            type: .error
        )
    }
    
    private func performLogin() {
        guard let url = URL(string: kimaiURL) else {
            authViewModel.errorMessage = "Bitte gültige URL eingeben"
            showToast = true
            return
        }
        
        let name = instanceName.isEmpty ? "Kimai Instance" : instanceName
        
        Task {
            await authViewModel.login(kimaiURL: url, apiToken: apiToken, instanceName: name)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}

