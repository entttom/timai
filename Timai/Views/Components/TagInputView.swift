//
//  TagInputView.swift
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

// MARK: - FlowLayout für automatisches Wrapping
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            var frames: [CGRect] = []
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    // Neue Zeile
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = size.height
                } else {
                    lineHeight = max(lineHeight, size.height)
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                currentX += size.width + spacing
            }
            
            self.frames = frames
            self.size = CGSize(
                width: maxWidth,
                height: frames.last?.maxY ?? 0
            )
        }
    }
}

/// Wiederverwendbare Eingabe für Tags mit Chips + Vorschlagsliste
struct TagInputView: View {
    @Binding var tags: [String]
    let knownTags: [String]
    let placeholder: String
    let onCreateTag: ((String) async throws -> Void)?
    let onRemoveTag: ((String) async throws -> Void)?
    let onSearchTags: ((String) async -> [String])? // Callback für dynamische API-Suche
    
    @State private var inputText: String = ""
    @State private var isFocused: Bool = false
    @State private var isCreatingTag = false
    @FocusState private var isTextFieldFocused: Bool
    @State private var dynamicSuggestions: [String] = [] // Tags von API während der Eingabe
    @State private var isSearchingTags = false
    @State private var searchTask: Task<Void, Never>? // Für Debouncing
    
    private var filteredSuggestions: [String] {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowerExisting = Set(tags.map { $0.lowercased() })
        
        // Wenn 2+ Zeichen eingegeben wurden, verwende dynamische API-Ergebnisse
        if trimmed.count >= 2, let onSearchTags = onSearchTags {
            let apiTags = dynamicSuggestions.filter { !lowerExisting.contains($0.lowercased()) }
            let localTags = knownTags.filter { 
                !lowerExisting.contains($0.lowercased()) && 
                $0.localizedCaseInsensitiveContains(trimmed) 
            }
            
            // Kombiniere API- und lokale Tags, entferne Duplikate
            var combined = Set<String>()
            for tag in localTags {
                combined.insert(tag)
            }
            for tag in apiTags {
                combined.insert(tag)
            }
            
            return Array(combined).sorted { $0.lowercased() < $1.lowercased() }.prefix(10).map { $0 }
        }
        
        // Bei weniger als 2 Zeichen oder leer: nur lokale Tags
        let availableTags = knownTags.filter { !lowerExisting.contains($0.lowercased()) }
        
        if trimmed.isEmpty {
            // Zeige Vorschläge nur wenn fokussiert
            if isTextFieldFocused && !availableTags.isEmpty {
                return Array(availableTags.prefix(10))
            }
            return []
        }
        
        // Bei 1 Zeichen: nur lokale Tags filtern
        return availableTags
            .filter { $0.localizedCaseInsensitiveContains(trimmed) }
            .prefix(10)
            .map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Aktuelle Tags als Chips
            if !tags.isEmpty {
                WrappingTagChips(tags: tags) { tagToRemove in
                    Task {
                        await removeTag(tagToRemove)
                    }
                }
                .padding(.bottom, 4)
            }
            
            // Eingabefeld mit Icon
            HStack(spacing: 10) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.timaiHighlight.opacity(0.7))
                
                TextField(placeholder, text: $inputText, onCommit: addFromInput)
                    .textInputAutocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused($isTextFieldFocused)
                    .onChange(of: inputText) { newValue in
                        // Wenn der Nutzer ein Komma eintippt, sofort Tag übernehmen
                        if newValue.contains(",") {
                            searchTask?.cancel()
                            addFromInput()
                            return
                        }
                        
                        // Cancle vorherige Suche (Debouncing)
                        searchTask?.cancel()
                        
                        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        // Wenn 2+ Zeichen eingegeben wurden, suche in der API (mit Debouncing)
                        if trimmed.count >= 2, let onSearchTags = onSearchTags {
                            searchTask = Task {
                                // Warte 300ms bevor die Suche startet (Debouncing)
                                try? await Task.sleep(nanoseconds: 300_000_000)
                                
                                // Prüfe ob Task noch aktiv ist (nicht gecancelt)
                                guard !Task.isCancelled else { return }
                                
                                await searchTagsInAPI(trimmed)
                            }
                        } else {
                            // Bei weniger als 2 Zeichen: leere dynamische Vorschläge
                            dynamicSuggestions = []
                        }
                    }
                
                if isCreatingTag {
                    ProgressView()
                        .scaleEffect(0.8)
                        .padding(.trailing, 4)
                } else if isSearchingTags {
                    ProgressView()
                        .scaleEffect(0.8)
                        .padding(.trailing, 4)
                } else if !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button {
                        addFromInput()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.timaiHighlight)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.timaiGray.opacity(0.3))
            .cornerRadius(10)
            
            // Vorschläge mit besserem Design
            if !filteredSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("timesheetEdit.tags.suggestions".localized())
                            .font(.caption)
                            .foregroundColor(.timaiSubheaderColor)
                        
                        if !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("(\(filteredSuggestions.count))")
                                .font(.caption2)
                                .foregroundColor(.timaiSubheaderColor.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 4)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(filteredSuggestions, id: \.self) { suggestion in
                                Button {
                                    addTag(suggestion)
                                    inputText = "" // Leere das Eingabefeld nach Auswahl
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "tag")
                                            .font(.system(size: 11))
                                        Text(suggestion)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.timaiHighlight.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.timaiHighlight.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                    .foregroundColor(.timaiHighlight)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func addFromInput() {
        let newTags = TagUtils.tags(from: inputText)
        for tag in newTags {
            addTag(tag)
        }
        inputText = ""
    }
    
    private func addTag(_ tag: String) {
        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Duplikate vermeiden (case-insensitive)
        if !tags.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            tags.append(trimmed)
            
            // Prüfe, ob Tag existiert, sonst erstelle ihn
            let lowerKnown = knownTags.map { $0.lowercased() }
            if !lowerKnown.contains(trimmed.lowercased()) {
                // Neuer Tag - erstelle ihn sofort
                Task {
                    await createTagIfNeeded(trimmed)
                }
            }
        }
    }
    
    private func createTagIfNeeded(_ tagName: String) async {
        guard let onCreateTag = onCreateTag else { return }
        guard !isCreatingTag else { return }
        
        isCreatingTag = true
        do {
            try await onCreateTag(tagName)
        } catch {
            // Tag aus der Liste entfernen, wenn Erstellung fehlgeschlagen ist
            await MainActor.run {
                tags.removeAll { $0.caseInsensitiveCompare(tagName) == .orderedSame }
            }
        }
        isCreatingTag = false
    }
    
    private func removeTag(_ tagName: String) async {
        // Entferne Tag aus der Liste
        tags.removeAll { $0.caseInsensitiveCompare(tagName) == .orderedSame }
        
        // Informiere über Tag-Entfernung (für Cleanup)
        if let onRemoveTag = onRemoveTag {
            do {
                try await onRemoveTag(tagName)
            } catch {
                // Fehler beim Entfernen ist nicht kritisch
            }
        }
    }
    
    private func searchTagsInAPI(_ searchTerm: String) async {
        guard let onSearchTags = onSearchTags, searchTerm.count >= 2 else {
            dynamicSuggestions = []
            return
        }
        
        isSearchingTags = true
        let results = await onSearchTags(searchTerm)
        dynamicSuggestions = results
        isSearchingTags = false
    }
}

/// Einfache, umbruchende Chip-Darstellung für Tags
struct WrappingTagChips: View {
    let tags: [String]
    let onRemove: (String) -> Void
    
    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                tagChip(tag)
            }
        }
    }
    
    private func tagChip(_ tag: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "tag.fill")
                .font(.system(size: 10))
                .foregroundColor(.timaiHighlight.opacity(0.8))
            
            Text(tag)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.timaiTextBlack)
            
            Button {
                onRemove(tag)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.timaiGrayTone2.opacity(0.7))
            }
            .buttonStyle(.plain)
            .padding(.leading, 2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.timaiHighlight.opacity(0.12))
                .overlay(
                    Capsule()
                        .stroke(Color.timaiHighlight.opacity(0.25), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}


