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
    
    var body: some View {
        VStack(spacing: AppConstants.contentSpacing(for: numberOfColumns)) {
            // Icône globe centrée
            Image(systemName: "globe")
                .font(AppConstants.contentTitleFont(for: numberOfColumns))
                .foregroundColor(.secondary)

            // Titre nettoyé
            Text(cleanedTitle)
                .font(AppConstants.contentTitleFont(for: numberOfColumns))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .padding(AppConstants.contentPadding(for: numberOfColumns))
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
