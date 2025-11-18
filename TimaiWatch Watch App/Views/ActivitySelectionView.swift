//
//  ActivitySelectionView.swift
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

struct ActivitySelectionView: View {
    let customer: WatchProjectSelectionViewModel.CustomerItem
    let project: WatchProjectSelectionViewModel.ProjectItem
    @Binding var isPresented: Bool
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var projectSelectionViewModel: WatchProjectSelectionViewModel
    var onActivitySelected: ((WatchProjectSelectionViewModel.ActivityItem) -> Void)?
    var navigationDestination: ((WatchProjectSelectionViewModel.CustomerItem, WatchProjectSelectionViewModel.ProjectItem, WatchProjectSelectionViewModel.ActivityItem) -> AnyView)?
    
    var body: some View {
        List {
            if projectSelectionViewModel.isLoadingActivities {
                ProgressView()
            } else if projectSelectionViewModel.activities.isEmpty {
                Text("watch.selection.noActivities".localized())
                    .foregroundColor(.gray)
            } else {
                ForEach(projectSelectionViewModel.activities) { activity in
                    if let destination = navigationDestination {
                        NavigationLink(destination: destination(customer, project, activity)) {
                            Text(activity.name)
                        }
                    } else {
                        NavigationLink(destination: TimerSummaryView(customer: customer, project: project, activity: activity, isPresented: $isPresented, navigationPath: $navigationPath)) {
                            Text(activity.name)
                        }
                    }
                }
            }
        }
        .navigationTitle("watch.selection.activity".localized())
        .onAppear {
            projectSelectionViewModel.loadActivities(for: project.id)
        }
    }
}

