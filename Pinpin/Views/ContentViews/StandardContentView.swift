//
//  StandardContentView.swift
//  Pinpin
//
//  Vue spécialisée pour le contenu standard (format adaptatif)
//

import SwiftUI

struct StandardContentView: View {
    let item: ContentItem
    
    // Cache du résultat hasImage pour éviter les recalculs
    private let cachedHasImage: Bool
    
    init(item: ContentItem) {
        self.item = item
        // Calculer une seule fois à l'initialisation
        self.cachedHasImage = Self.checkHasImage(item: item)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if cachedHasImage {
                SmartAsyncImage(item: item)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(contentMode: .fit)
            } else {
                // Pas d'image, afficher le titre
                Text(item.title)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(8)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
            }
        }
    }
    
    private static func checkHasImage(item: ContentItem) -> Bool {
        // Check si on a une image dans SwiftData
        if item.imageData != nil {
            return true
        }
        
        // Check si on a une URL d'image valide
        if let thumbnailUrl = item.thumbnailUrl,
           !thumbnailUrl.isEmpty,
           !thumbnailUrl.hasPrefix("images/"),
           !thumbnailUrl.hasPrefix("file:///var/mobile/Media/PhotoData/") {
            return true
        }
        
        return false
    }
}
