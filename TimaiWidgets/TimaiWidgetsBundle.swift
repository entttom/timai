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
    #if os(iOS)
    @available(iOS 17.0, *)
    var body: some Widget {
        TimaiWidgetsLiveActivity()
    }
    #else
    var body: some Widget {
        EmptyWidgetView()
    }
    #endif
}

#if !os(iOS)
// Dummy Widget für macOS
struct EmptyWidgetView: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "EmptyWidget", provider: EmptyProvider()) { _ in
            Text("Timai Widgets sind nur auf iOS verfügbar")
        }
        .configurationDisplayName("Timai")
        .description("Timai Widgets")
    }
}

struct EmptyProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let entry = SimpleEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}
#endif
