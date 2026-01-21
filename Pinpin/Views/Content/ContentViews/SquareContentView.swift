//
//  SquareContentView.swift
//  Pinpin
//
//  Vue spécialisée pour le contenu carré (Apple Music, Apple Books)
//

import SwiftUI

struct SquareContentView: View {
    let item: ContentItem
    
    var body: some View {
        VStack(alignment: .leading) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .aspectRatio(1.0, contentMode: .fit)
                .overlay(
                    SmartAsyncImage(item: item)
                        .aspectRatio(contentMode: isAppStoreContent ? .fill : .fill)
                        .scaleEffect(isZoomedContent ? 1.50 : 1)
                        .clipped()
                )
        }
    }
    
    // MARK: - Computed Properties
    
    private var isZoomedContent: Bool {
        guard let url = item.url else { return false }
        return url.contains("music.apple.com")
    }
    
    private var isAppStoreContent: Bool {
        guard let url = item.url else { return false }
        return url.contains("apps.apple.com")
    }
}
