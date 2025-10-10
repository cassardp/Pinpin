//
//  ContentItemCard.swift
//  Pinpin
//
//  Main content item card that delegates to specialized views
//

import SwiftUI

struct ContentItemCard: View {
    let item: ContentItem
    private let userPreferences = UserPreferences.shared
    let cornerRadius: CGFloat
    let numberOfColumns: Int
    let isSelectionMode: Bool
    let onSelectionTap: (() -> Void)?
    let onItemTap: (() -> Void)?
    let heroNamespace: Namespace.ID
    @State private var hapticTrigger: Int = 0
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Vue unifiée pour toutes les catégories
            unifiedContentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .matchedTransitionSource(id: item.id, in: heroNamespace) { source in
                    source
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                }
            
            // URL en overlay dans le coin bas gauche
            if userPreferences.showURLs, let url = item.url, !url.isEmpty {
                Text(shortenURL(url))
                    .font(.caption2)
                    .foregroundColor(.primary.opacity(0.7))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 4))
                    .padding(8)
                    .onTapGesture {
                        UIPasteboard.general.string = url
                        hapticTrigger += 1
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.8)).combined(with: .move(edge: .bottom)),
                        removal: .opacity.combined(with: .scale(scale: 0.8))
                    ))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .animation(.smooth(duration: 0.4), value: cornerRadius)
        .animation(.smooth(duration: 0.5), value: userPreferences.showURLs)
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    // Le long press est géré par le contextMenu dans MainView
                    // On ne fait rien ici, juste bloquer le tap
                }
        )
        .onTapGesture {
            if isSelectionMode {
                // En mode sélection : appeler le callback de sélection
                onSelectionTap?()
            } else if isLinkWithoutImage, let urlString = item.url {
                // Lien sans image : ouvrir directement l'URL
                handleContentTap(urlString: urlString)
            } else {
                // Mode normal : ouvrir la vue détail avec transition hero
                onItemTap?()
            }
        }
        // S'assurer que la zone de toucher ne dépasse pas les limites visuelles avec les coins arrondis
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    private func handleContentTap(urlString: String) {
        // Pour les URLs locales, essayer d'utiliser l'URL originale des métadonnées
        if urlString.hasPrefix("file:///") {
            // Vérifier si on a une URL originale dans les métadonnées
            if let originalUrl = item.metadataDict["original_url"] {
                if let url = URL(string: originalUrl) {
                    UIApplication.shared.open(url)
                    return
                }
            } else {
                // Détection simple basée sur le chemin
                if urlString.contains("/PhotoData/") || urlString.contains("/DCIM/") {
                    if let photosUrl = URL(string: "photos-redirect://") {
                        UIApplication.shared.open(photosUrl)
                        return
                    }
                }
            }
        }
        
        // Fallback : ouvrir l'URL normale (seulement si ce n'est pas file://)
        if !urlString.hasPrefix("file:///"), let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    /// Raccourcit une URL pour afficher seulement le domaine principal
    private func shortenURL(_ urlString: String) -> String {
        // Cas spécial pour les URLs locales
        if urlString.hasPrefix("file:///") {
            return "Local"
        }
        
        guard let url = URL(string: urlString),
              let host = url.host else {
            return urlString
        }
        
        // Supprimer le "www." si présent
        let cleanHost = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        
        // Mappings spéciaux pour des domaines connus
        let domainMappings: [String: String] = [
            "twitter.com": "x.com",
            "m.twitter.com": "x.com",
            "mobile.twitter.com": "x.com",
            "www.instagram.com": "instagram.com",
            "m.instagram.com": "instagram.com",
            "www.youtube.com": "youtube.com",
            "m.youtube.com": "youtube.com",
            "youtu.be": "youtube.com",
            "www.facebook.com": "facebook.com",
            "m.facebook.com": "facebook.com",
            "www.tiktok.com": "tiktok.com",
            "vm.tiktok.com": "tiktok.com",
            "www.linkedin.com": "linkedin.com",
            "m.linkedin.com": "linkedin.com",
            "pin.it": "pinterest.com",
            "www.pinterest.com": "pinterest.com",
            "www.reddit.com": "reddit.com",
            "old.reddit.com": "reddit.com",
            "m.reddit.com": "reddit.com",
            "www.amazon.com": "amazon.com",
            "www.amazon.fr": "amazon.fr",
            "smile.amazon.com": "amazon.com",
            "www.netflix.com": "netflix.com",
            "www.spotify.com": "spotify.com",
            "open.spotify.com": "spotify.com",
            "music.apple.com": "apple.com/music",
            "apps.apple.com": "app store",
            "play.google.com": "play store"
        ]
        
        // Vérifier les mappings spéciaux
        if let mappedDomain = domainMappings[cleanHost] {
            return mappedDomain
        }
        
        // Pour les autres domaines, retourner le host nettoyé
        return cleanHost
    }
    
    // MARK: - Vue unifiée

    private var unifiedContentView: some View {
        ContentCardView(item: item, numberOfColumns: numberOfColumns, isSelectionMode: isSelectionMode)
    }
    
    // Propriété calculée pour le meilleur titre disponible
    private var bestTitle: String? {
        // Priorité : best_title des métadonnées > title > URL nettoyée
        if let bestTitle = item.metadataDict["best_title"], !bestTitle.isEmpty {
            return bestTitle
        }
        
        if !item.title.isEmpty && item.title != "Nouveau contenu" {
            return item.title
        }
        
        // Fallback sur l'URL nettoyée
        if let url = item.url, !url.isEmpty {
            return shortenURL(url)
        }
        
        return nil
    }
    
    /// Détermine si c'est un lien sans image
    private var isLinkWithoutImage: Bool {
        // Pas d'image data
        guard item.imageData == nil else { return false }
        
        // Pas de thumbnail valide
        if let thumbnail = item.thumbnailUrl,
           !thumbnail.isEmpty,
           !thumbnail.hasPrefix("images/"),
           !thumbnail.hasPrefix("file:///var/mobile/Media/PhotoData/"),
           !thumbnail.hasPrefix("file:///") {
            return false
        }
        
        // Mais a une URL
        return item.url != nil && !(item.url?.isEmpty ?? true)
    }
}
