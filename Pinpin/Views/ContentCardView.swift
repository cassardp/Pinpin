//
//  ContentCardView.swift
//  Pinpin
//
//  Vue unifiée simple pour tous les types de contenu
//

import SwiftUI

struct ContentCardView: View {
    let item: ContentItem
    
    var body: some View {
        if isTikTokContent {
            tiktokContentView
        } else if shouldUseSquareFormat {
            squareContentView
        } else {
            standardContentView
        }
    }
    
    // MARK: - Content Views
    
    private var tiktokContentView: some View {
        VStack(alignment: .leading) {
            Rectangle()
                .aspectRatio(9/16, contentMode: .fit)
                .overlay(
                    SmartAsyncImage(item: item)
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                )
        }
    }
    
    private var squareContentView: some View {
        VStack(alignment: .leading) {
            Rectangle()
                .fill(Color.gray.opacity(0.3)) // Même couleur que le placeholder
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
    
    private var standardContentView: some View {
        VStack(alignment: .leading) {
            SmartAsyncImage(item: item)
                .frame(maxWidth: .infinity)
                .aspectRatio(contentMode: .fit)
        }
    }
    
    // MARK: - Computed Properties
    
    private var isTikTokContent: Bool {
        guard let url = item.url else { return false }
        return url.contains("tiktok.com") || url.contains("vm.tiktok.com")
    }
    
    private var isAppleMusicContent: Bool {
        guard let url = item.url else { return false }
        return url.contains("music.apple.com")
    }
    
    private var shouldUseSquareFormat: Bool {
        guard let url = item.url else { return false }
        
        // Format carré uniquement pour Apple Music et Apple Books
        let isAppleMusic = url.contains("music.apple.com")
        let isAppleBooks = url.contains("books.apple.com") || 
                          url.contains("itunes.apple.com/book") || 
                          url.contains("itunes.apple.com/audiobook")
        
        return isAppleMusic || isAppleBooks
    }
}
