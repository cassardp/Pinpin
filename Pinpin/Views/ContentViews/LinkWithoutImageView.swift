//
//  LinkWithoutImageView.swift
//  Pinpin
//
//  Vue pour les liens sans image (affiche icône globe + titre)
//

import SwiftUI

struct LinkWithoutImageView: View {
    let item: ContentItem
    let numberOfColumns: Int
    
    private var adaptive: AdaptiveContentProperties {
        AdaptiveContentProperties(numberOfColumns: numberOfColumns)
    }
    
    var body: some View {
        VStack(spacing: adaptive.spacing) {
            // Icône globe centrée
            Image(systemName: "globe")
                .font(adaptive.font)
                .foregroundColor(Color(.systemBackground))
                            
            // Titre nettoyé
            Text(cleanedTitle)
                .font(adaptive.font)
                .foregroundColor(Color(.systemBackground))
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .padding(adaptive.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primary)
    }
    
    /// Nettoie le titre en enlevant les préfixes http://, https://, www. et les / à la fin
    private var cleanedTitle: String {
        var title = item.bestTitle
        
        // Enlever les préfixes de protocole
        if title.hasPrefix("https://") {
            title = String(title.dropFirst(8))
        } else if title.hasPrefix("http://") {
            title = String(title.dropFirst(7))
        }
        
        // Enlever www.
        if title.hasPrefix("www.") {
            title = String(title.dropFirst(4))
        }
        
        // Enlever les / à la fin
        while title.hasSuffix("/") {
            title = String(title.dropLast())
        }
        
        return title
    }
}
