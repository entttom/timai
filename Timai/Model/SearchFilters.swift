//
//  SearchFilters.swift
//  Timai
//
//  Copyright (c) 2025 Dr. Thomas Entner.
//  All rights reserved.
//
//  Licensed under the Business Source License 1.1.
//  Usage is free for non-commercial and personal use.
//  Commercial use requires a commercial license.
//
import Foundation

struct SearchFilters: Equatable {
    var dateFrom: Date?
    var dateTo: Date?
    var selectedCustomerId: Int?
    var selectedProjectId: Int?
    var selectedTags: [String]
    
    init(
        dateFrom: Date? = nil,
        dateTo: Date? = nil,
        selectedCustomerId: Int? = nil,
        selectedProjectId: Int? = nil,
        selectedTags: [String] = []
    ) {
        self.dateFrom = dateFrom
        self.dateTo = dateTo
        self.selectedCustomerId = selectedCustomerId
        self.selectedProjectId = selectedProjectId
        self.selectedTags = selectedTags
    }
    
    var hasActiveFilters: Bool {
        return dateFrom != nil ||
               dateTo != nil ||
               selectedCustomerId != nil ||
               selectedProjectId != nil ||
               !selectedTags.isEmpty
    }
    
    mutating func reset() {
        dateFrom = nil
        dateTo = nil
        selectedCustomerId = nil
        selectedProjectId = nil
        selectedTags = []
    }
}

