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
    @State private var kimaiURL: String = ""
    @State private var apiToken: String = ""
    @State private var showToast = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case url, token
    }
    
    var body: some View {
        ZStack {
            // Background
            LoginBackgroundView()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Logo oben
                Image("TimaiLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 120)
                    .padding(.top, 80)
                
                Spacer()
                
                // Login Form - vertikal zentriert
                VStack(spacing: 20) {
                    // URL Input
                    HStack(spacing: 15) {
                        Image(systemName: "link")
                            .font(.system(size: 18))
                            .foregroundColor(.timaiGrayTone3)
                            .frame(width: 20)
                        
                        TextField("https://demo.kimai.org/api/", text: $kimaiURL)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .url)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .token
                            }
                    }
                    .padding()
                    .background(
                        Color.white.opacity(0.6)
                            .background(.ultraThinMaterial)
                    )
                    .cornerRadius(5)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 5)
                    
                    // API Token Input
                    HStack(spacing: 15) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.timaiGrayTone3)
                            .frame(width: 20)
                        
                        SecureField("API Token", text: $apiToken)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .token)
                            .submitLabel(.go)
                            .onSubmit {
                                performLogin()
                            }
                    }
                    .padding()
                    .background(
                        Color.white.opacity(0.6)
                            .background(.ultraThinMaterial)
                    )
                    .cornerRadius(5)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 5)
                    
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
        
        Task {
            await authViewModel.login(kimaiURL: url, apiToken: apiToken)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}

