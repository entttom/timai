//
//  CustomerSelectionView.swift
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

struct CustomerSelectionView: View {
    @Binding var isPresented: Bool
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var projectSelectionViewModel: WatchProjectSelectionViewModel
    @State private var selectedCustomer: WatchProjectSelectionViewModel.CustomerItem?
    var onCustomerSelected: ((WatchProjectSelectionViewModel.CustomerItem) -> Void)?
    var navigationDestination: ((WatchProjectSelectionViewModel.CustomerItem) -> AnyView)?
    
    var body: some View {
        List {
            if projectSelectionViewModel.isLoadingCustomers {
                ProgressView()
            } else if projectSelectionViewModel.customers.isEmpty {
                Text("watch.selection.noCustomers".localized())
                    .foregroundColor(.gray)
            } else {
                ForEach(projectSelectionViewModel.customers) { customer in
                    if let destination = navigationDestination {
                        NavigationLink(destination: destination(customer)) {
                            Text(customer.name)
                        }
                    } else {
                        NavigationLink(destination: ProjectSelectionView(customer: customer, isPresented: $isPresented, navigationPath: $navigationPath)) {
                            Text(customer.name)
                        }
                    }
                }
            }
        }
        .navigationTitle("watch.selection.customer".localized())
        .onAppear {
            if projectSelectionViewModel.customers.isEmpty {
                projectSelectionViewModel.loadCustomers()
            }
        }
    }
}

