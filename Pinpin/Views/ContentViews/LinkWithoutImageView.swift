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
                #if os(macOS)
                .foregroundColor(Color(nsColor: .controlBackgroundColor))
                #else
                .foregroundColor(Color(.systemBackground))
                #endif
                            
            // Titre nettoyé
            Text(cleanedTitle)
                .font(adaptive.font)
                #if os(macOS)
                .foregroundColor(Color(nsColor: .controlBackgroundColor))
                #else
                .foregroundColor(Color(.systemBackground))
                #endif
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .padding(adaptive.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #if os(macOS)
        .background(Color(nsColor: .controlBackgroundColor))
        #else
        .background(Color(.systemBackground))
        #endif
    }
    
    /// Retourne le meilleur titre disponible
    private var cleanedTitle: String {
        return item.bestTitle
    }
}
