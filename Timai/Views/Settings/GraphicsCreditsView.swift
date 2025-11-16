//
//  GraphicsCreditsView.swift
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

struct GraphicsCreditsView: View {
    let credits = Credits.graphics
    
    var body: some View {
        List {
            ForEach(credits, id: \.name) { credit in
                VStack(alignment: .leading, spacing: 6) {
                    Text(credit.name)
                        .font(.headline)
                        .foregroundColor(.timaiTextBlack)
                    
                    Text("\("graphicsDetail.detailText.seperator".localized()) \(credit.author)")
                        .font(.subheadline)
                        .foregroundColor(.timaiSubheaderColor)
                    
                    if let website = credit.website {
                        Link(destination: website) {
                            HStack(spacing: 4) {
                                Image(systemName: "link")
                                    .font(.caption2)
                                Text(website.absoluteString)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            .font(.caption)
                            .foregroundColor(.timaiHighlight)
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .navigationTitle("graphicsDetail.navigationTitle".localized())
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#Preview {
    NavigationStack {
        GraphicsCreditsView()
    }
}

