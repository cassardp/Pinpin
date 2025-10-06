//
//  ContentCardView.swift
//  Pinpin
//
//  Vue principale qui délègue à des vues spécialisées selon le type de contenu
//

import SwiftUI

struct ContentCardView: View {
    let item: ContentItem
    let numberOfColumns: Int
    let isSelectionMode: Bool

    var body: some View {
        Group {
            switch contentType {
            case .textOnly:
                TextOnlyContentView(item: item, numberOfColumns: numberOfColumns, isSelectionMode: isSelectionMode)
            case .tiktok:
                TikTokContentView(item: item)
            case .square:
                SquareContentView(item: item)
            case .standard:
                StandardContentView(item: item)
            }
        }
    }
    
    // MARK: - Content Type Detection
    
    private enum ContentViewType {
        case textOnly
        case tiktok
        case square
        case standard
    }
    
    private var contentType: ContentViewType {
        // Vérifier d'abord si c'est du contenu texte uniquement
        if hasNoVisualContent {
            return .textOnly
        }
        
        guard let url = item.url else { return .standard }
        
        // TikTok content
        if url.contains("tiktok.com") || url.contains("vm.tiktok.com") {
            return .tiktok
        }
        
        // Square format content
        let isAppleMusic = url.contains("music.apple.com")
        let isAppleBooks = url.contains("books.apple.com") || 
                          url.contains("itunes.apple.com/book") || 
                          url.contains("itunes.apple.com/audiobook")
        
        if isAppleMusic || isAppleBooks {
            return .square
        }
        
        // Default to standard
        return .standard
    }
    
    /// Détermine si le contenu n'a pas d'éléments visuels (image/vidéo)
    private var hasNoVisualContent: Bool {
        // Optimisation: vérifier d'abord imageData (le plus rapide)
        if item.imageData != nil {
            return false
        }
        
        // Vérifier thumbnail
        if let thumbnail = item.thumbnailUrl,
           !thumbnail.isEmpty,
           !thumbnail.hasPrefix("images/"),
           !thumbnail.hasPrefix("file:///var/mobile/Media/PhotoData/") {
            return false
        }
        
        // Vérifier URL web
        if let urlString = item.url,
           !urlString.hasPrefix("file:///"),
           let url = URL(string: urlString),
           url.scheme == "http" || url.scheme == "https" {
            return false
        }
        
        return true
    }
}
