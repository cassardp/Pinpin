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
    
    /// Retourne le meilleur titre disponible
    private var cleanedTitle: String {
        return item.bestTitle
    }
}
