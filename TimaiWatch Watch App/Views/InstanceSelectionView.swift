//
//  InstanceSelectionView.swift
//  TimaiWatch
//
//  Copyright (c) 2025 Dr. Thomas Entner.
//  All rights reserved.
//
//  Licensed under the Business Source License 1.1.
//  Usage is free for non-commercial and personal use.
//  Commercial use requires a commercial license.
//
import SwiftUI

struct InstanceSelectionView: View {
    @EnvironmentObject var instanceViewModel: WatchInstanceSelectionViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingErrorAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                if instanceViewModel.isLoading {
                    ProgressView("watch.instances.loading".localized())
                } else if instanceViewModel.instances.isEmpty {
                    Text("watch.instances.empty".localized())
                        .foregroundColor(.gray)
                } else {
                    ForEach(instanceViewModel.instances) { instance in
                        Button {
                            instanceViewModel.switchToInstance(instance)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(instance.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(instance.apiEndpoint)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                if instance.isActive {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("watch.instances.title".localized())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("watch.instances.cancel".localized()) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                instanceViewModel.loadInstances()
            }
            .onChange(of: instanceViewModel.errorMessage) { _, newValue in
                if newValue != nil {
                    showingErrorAlert = true
                }
            }
            .alert("watch.error.title".localized(), isPresented: $showingErrorAlert, actions: {
                Button("watch.error.ok".localized()) {
                    instanceViewModel.errorMessage = nil
                }
            }, message: {
                Text(instanceViewModel.errorMessage ?? "Unbekannter Fehler")
            })
        }
    }
}

struct InstanceSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        InstanceSelectionView()
            .environmentObject(WatchInstanceSelectionViewModel())
    }
}

