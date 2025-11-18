//
//  ProjectSelectionView.swift
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

struct ProjectSelectionView: View {
    let customer: WatchProjectSelectionViewModel.CustomerItem
    @Binding var isPresented: Bool
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var projectSelectionViewModel: WatchProjectSelectionViewModel
    @State private var selectedProject: WatchProjectSelectionViewModel.ProjectItem?
    var onProjectSelected: ((WatchProjectSelectionViewModel.ProjectItem) -> Void)?
    var navigationDestination: ((WatchProjectSelectionViewModel.CustomerItem, WatchProjectSelectionViewModel.ProjectItem) -> AnyView)?
    
    var body: some View {
        List {
            if projectSelectionViewModel.isLoadingProjects {
                ProgressView()
            } else if projectSelectionViewModel.projects.isEmpty {
                Text("watch.selection.noProjects".localized())
                    .foregroundColor(.gray)
            } else {
                ForEach(projectSelectionViewModel.projects.filter { $0.customerId == customer.id }) { project in
                    if let destination = navigationDestination {
                        NavigationLink(destination: destination(customer, project)) {
                            Text(project.name)
                        }
                    } else {
                        NavigationLink(destination: ActivitySelectionView(customer: customer, project: project, isPresented: $isPresented, navigationPath: $navigationPath)) {
                            Text(project.name)
                        }
                    }
                }
            }
        }
        .navigationTitle("watch.selection.project".localized())
        .onAppear {
            projectSelectionViewModel.loadProjects(for: customer.id)
        }
    }
}
