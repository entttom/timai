//
//  ManualTimesheetView.swift
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

struct ManualTimesheetView: View {
    @Binding var isPresented: Bool
    @StateObject private var manualTimesheetViewModel = WatchManualTimesheetViewModel()
    @StateObject private var projectSelectionViewModel = WatchProjectSelectionViewModel()
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ManualTimesheetCustomerSelectionView(
                isPresented: $isPresented,
                navigationPath: $navigationPath,
                manualTimesheetViewModel: manualTimesheetViewModel
            )
            .environmentObject(projectSelectionViewModel)
            .onChange(of: isPresented) { _, isPresented in
                if !isPresented {
                    navigationPath = NavigationPath()
                    manualTimesheetViewModel.reset()
                }
            }
        }
    }
}

struct ManualTimesheetCustomerSelectionView: View {
    @Binding var isPresented: Bool
    @Binding var navigationPath: NavigationPath
    @ObservedObject var manualTimesheetViewModel: WatchManualTimesheetViewModel
    @EnvironmentObject var projectSelectionViewModel: WatchProjectSelectionViewModel
    
    var body: some View {
        List {
            if projectSelectionViewModel.isLoadingCustomers {
                ProgressView()
            } else if projectSelectionViewModel.customers.isEmpty {
                Text("watch.selection.noCustomers".localized())
                    .foregroundColor(.gray)
            } else {
                ForEach(projectSelectionViewModel.customers) { customer in
                    NavigationLink {
                        ManualTimesheetProjectSelectionView(
                            customer: customer,
                            isPresented: $isPresented,
                            navigationPath: $navigationPath,
                            manualTimesheetViewModel: manualTimesheetViewModel
                        )
                        .environmentObject(projectSelectionViewModel)
                    } label: {
                        Text(customer.name)
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

struct ManualTimesheetProjectSelectionView: View {
    let customer: WatchProjectSelectionViewModel.CustomerItem
    @Binding var isPresented: Bool
    @Binding var navigationPath: NavigationPath
    @ObservedObject var manualTimesheetViewModel: WatchManualTimesheetViewModel
    @EnvironmentObject var projectSelectionViewModel: WatchProjectSelectionViewModel
    
    var body: some View {
        List {
            if projectSelectionViewModel.isLoadingProjects {
                ProgressView()
            } else if projectSelectionViewModel.projects.isEmpty {
                Text("watch.selection.noProjects".localized())
                    .foregroundColor(.gray)
            } else {
                ForEach(projectSelectionViewModel.projects.filter { $0.customerId == customer.id }) { project in
                    NavigationLink {
                        ManualTimesheetActivitySelectionView(
                            customer: customer,
                            project: project,
                            isPresented: $isPresented,
                            navigationPath: $navigationPath,
                            manualTimesheetViewModel: manualTimesheetViewModel
                        )
                        .environmentObject(projectSelectionViewModel)
                    } label: {
                        Text(project.name)
                    }
                }
            }
        }
        .navigationTitle("watch.selection.project".localized())
        .onAppear {
            manualTimesheetViewModel.selectedCustomer = customer
            projectSelectionViewModel.loadProjects(for: customer.id)
        }
    }
}

struct ManualTimesheetActivitySelectionView: View {
    let customer: WatchProjectSelectionViewModel.CustomerItem
    let project: WatchProjectSelectionViewModel.ProjectItem
    @Binding var isPresented: Bool
    @Binding var navigationPath: NavigationPath
    @ObservedObject var manualTimesheetViewModel: WatchManualTimesheetViewModel
    @EnvironmentObject var projectSelectionViewModel: WatchProjectSelectionViewModel
    
    var body: some View {
        List {
            if projectSelectionViewModel.isLoadingActivities {
                ProgressView()
            } else if projectSelectionViewModel.activities.isEmpty {
                Text("watch.selection.noActivities".localized())
                    .foregroundColor(.gray)
            } else {
                ForEach(projectSelectionViewModel.activities) { activity in
                    NavigationLink {
                        ManualTimesheetDateSelectionView(
                            startDate: $manualTimesheetViewModel.startDate,
                            endDate: $manualTimesheetViewModel.endDate,
                            navigationPath: $navigationPath,
                            customer: customer,
                            project: project,
                            activity: activity,
                            isPresented: $isPresented,
                            manualTimesheetViewModel: manualTimesheetViewModel
                        )
                    } label: {
                        Text(activity.name)
                    }
                }
            }
        }
        .navigationTitle("watch.selection.activity".localized())
        .onAppear {
            manualTimesheetViewModel.selectedProject = project
            projectSelectionViewModel.loadActivities(for: project.id)
        }
    }
}

