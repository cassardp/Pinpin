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
    
    var body: some View {
        Group {
            switch contentType {
            case .textOnly:
                TextOnlyContentView(item: item, numberOfColumns: numberOfColumns)
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
        // Pas d'image stockée localement
        let hasNoImageData = item.imageData == nil
        
        // Pas d'URL d'image/thumbnail valide
        let hasNoThumbnail = item.thumbnailUrl?.isEmpty != false || 
                            item.thumbnailUrl?.hasPrefix("images/") == true ||
                            item.thumbnailUrl?.hasPrefix("file:///var/mobile/Media/PhotoData/") == true
        
        // Pas d'URL web valide pour une image
        let hasNoWebImage: Bool = {
            guard let urlString = item.url,
                  !urlString.hasPrefix("file:///"),
                  let url = URL(string: urlString),
                  url.scheme == "http" || url.scheme == "https" else {
                return true
            }
            return false
        }()
        
        // A du contenu textuel (titre ou description)
        let hasTextContent = !item.title.isEmpty || 
                           (item.itemDescription?.isEmpty == false)
        
        return hasNoImageData && hasNoThumbnail && hasNoWebImage && hasTextContent
    }
}
