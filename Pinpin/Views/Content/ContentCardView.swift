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
            case .linkWithoutImage:
                LinkWithoutImageView(item: item, numberOfColumns: numberOfColumns)
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
        case linkWithoutImage
        case tiktok
        case square
        case standard
    }
    
    private var contentType: ContentViewType {
        // Vérifier d'abord si c'est du contenu texte uniquement (note sans URL)
        if hasNoVisualContent {
            // Si pas d'URL ou URL vide, c'est une note textuelle
            if item.url == nil || item.url?.isEmpty == true {
                return .textOnly
            }
            // Sinon c'est un lien sans image
            return .linkWithoutImage
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
        // Vérifier d'abord imageData (le plus rapide)
        if item.imageData != nil {
            return false
        }
        
        // Vérifier thumbnail (URL distante valide)
        if let thumbnail = item.thumbnailUrl,
           !thumbnail.isEmpty,
           !thumbnail.hasPrefix("images/"),
           !thumbnail.hasPrefix("file:///var/mobile/Media/PhotoData/"),
           !thumbnail.hasPrefix("file:///") {
            return false
        }
        
        // Si on arrive ici, pas d'image disponible
        return true
    }
}
