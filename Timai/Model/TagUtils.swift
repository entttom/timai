//
//  TagUtils.swift
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

/// Hilfsfunktionen für das Konvertieren und Normalisieren von Tags
struct TagUtils {
    
    /// Konvertiert einen optionalen kommagetrennten String in ein normalisiertes Tag-Array.
    /// - Parameter string: z.B. `"Tag 1, tag2,  Tag 1 "`
    /// - Returns: z.B. `["Tag 1", "tag2"]` (getrimmt, ohne Duplikate, leere Einträge entfernt)
    static func tags(from string: String?) -> [String] {
        guard let string = string, !string.isEmpty else {
            return []
        }
        
        let rawTags = string
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Duplikate entfernen (case-insensitive), Reihenfolge beibehalten
        var seen = Set<String>()
        var result: [String] = []
        
        for tag in rawTags {
            let key = tag.lowercased()
            if !seen.contains(key) {
                seen.insert(key)
                result.append(tag)
            }
        }
        
        return result
    }
    
    /// Baut aus einem Tag-Array einen kommagetrennten String, wie ihn Kimai erwartet.
    /// - Parameter tags: z.B. `["Tag 1", "tag2", "Tag 1"]`
    /// - Returns: z.B. `"Tag 1,tag2"` oder `""` (leerer String) wenn keine Tags übrig sind, um Tags zu löschen
    static func string(from tags: [String]) -> String? {
        let cleaned = tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Wenn keine Tags vorhanden sind, gib leeren String zurück (nicht nil), um Tags zu löschen
        guard !cleaned.isEmpty else { return "" }
        
        var seen = Set<String>()
        var unique: [String] = []
        
        for tag in cleaned {
            let key = tag.lowercased()
            if !seen.contains(key) {
                seen.insert(key)
                unique.append(tag)
            }
        }
        
        return unique.isEmpty ? "" : unique.joined(separator: ", ")
    }
}


