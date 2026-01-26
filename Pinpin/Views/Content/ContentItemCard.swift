//
//  ContentItemCard.swift
//  Pinpin
//
//  Main content item card that delegates to specialized views
//

import SwiftUI

struct ContentItemCard: View {
    let item: ContentItem
    let cornerRadius: CGFloat
    let numberOfColumns: Int
    let isSelectionMode: Bool
    let onSelectionTap: (() -> Void)?

    @State private var hapticTrigger = 0
    @State private var isPressed = false
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            unifiedContentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isPressed)
        .animation(.smooth(duration: 0.4), value: cornerRadius)
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
        .onTapGesture {
            if isSelectionMode {
                onSelectionTap?()
            } else {
                // Effet visuel au tap
                hapticTrigger += 1
                withAnimation(.easeOut(duration: 0.1)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeOut(duration: 0.12)) {
                        isPressed = false
                    }
                }
                // Ouvrir l'URL après l'animation
                if let urlString = item.url, !urlString.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        handleContentTap(urlString: urlString)
                    }
                }
            }
        }
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
