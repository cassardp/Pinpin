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
                    Group {
                        if isAppleMusicContent {
                            // Crop 20% pour Apple Music (garde l'image carrée)
                            SmartAsyncImage(item: item)
                                .aspectRatio(contentMode: .fill)
                                .scaleEffect(1.50) // Zoom pour compenser le crop de 20%
                                .clipped()
                        } else {
                            SmartAsyncImage(item: item)
                                .aspectRatio(contentMode: .fill)
                                .clipped()
                        }
                    }
                )
        }
    }
    
    // MARK: - Computed Properties
    
    private var isAppleMusicContent: Bool {
        guard let url = item.url else { return false }
        return url.contains("music.apple.com")
    }
}
