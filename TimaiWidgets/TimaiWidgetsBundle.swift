//
//  TimaiWidgetsBundle.swift
//  TimaiWidgets
//
//  Copyright (c) 2025 Dr. Thomas Entner.
//  All rights reserved.
//
//  Licensed under the Business Source License 1.1.
//  Usage is free for non-commercial and personal use.
//  Commercial use requires a commercial license.
//
import WidgetKit
import SwiftUI

@main
struct TimaiWidgetsBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 17.0, *) {
            TimaiWidgetsLiveActivity()
        }
    }
}
