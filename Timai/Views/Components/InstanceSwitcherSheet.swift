//
//  InstanceSwitcherSheet.swift
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

struct InstanceSwitcherSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var instanceManager = InstanceManager.shared
    
    @State private var showingAddInstance = false
    @State private var isSwitching = false
    
    var body: some View {
        NavigationView {
            List {
                // List of instances
                Section {
                    ForEach(instanceManager.instances) { instance in
                        Button {
                            switchToInstance(instance)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(instance.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(instance.apiEndpoint.absoluteString)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                                
                                Spacer()
                                
                                if instance.isActive {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.timaiHighlight)
                                }
                            }
                        }
                        .disabled(instance.isActive || isSwitching)
                    }
                } header: {
                    Text("instanceSwitcher.section.instances".localized())
                }
                
                // Actions
                Section {
                    Button {
                        showingAddInstance = true
                    } label: {
                        Label("instanceSwitcher.button.addNew".localized(), systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("instanceSwitcher.title".localized())
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("instanceSwitcher.button.close".localized()) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddInstance) {
                AddInstanceView()
                    .environmentObject(authViewModel)
            }
            .overlay {
                if isSwitching {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            
                            Text("instanceSwitcher.switching".localized())
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
    }
    
    private func switchToInstance(_ instance: KimaiInstance) {
        guard !instance.isActive else { return }
        
        isSwitching = true
        
        Task {
            await authViewModel.switchToInstance(instance)
            
            // Small delay for better UX
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            
            isSwitching = false
            dismiss()
        }
    }
}

#Preview {
    InstanceSwitcherSheet()
        .environmentObject(AuthViewModel())
}


