//
//  StandardContentView.swift
//  Pinpin
//
//  Vue spécialisée pour le contenu standard (format adaptatif)
//

import SwiftUI

struct StandardContentView: View {
    let item: ContentItem
    let numberOfColumns: Int
    
    // Cache du résultat hasImage pour éviter les recalculs
    private let cachedHasImage: Bool
    
    init(item: ContentItem, numberOfColumns: Int) {
        self.item = item
        self.numberOfColumns = numberOfColumns
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
                // Note: Ceci est un fallback, normalement géré par TextOnlyContentView
                Text(item.title)
                    .font(AppConstants.contentTitleFont(for: numberOfColumns))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(AppConstants.contentTitleLineLimit(for: numberOfColumns))
                    .padding(AppConstants.contentPadding(for: numberOfColumns))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            #if os(macOS)
                            .fill(Color(nsColor: .windowBackgroundColor))
                            #else
                            .fill(Color(.systemGray6))
                            #endif
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
