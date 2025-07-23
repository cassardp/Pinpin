//
//  ContentItemCard.swift
//  Neeed2
//
//  Main content item card that delegates to specialized views
//

import SwiftUI

struct ContentItemCard: View {
    @ObservedObject var item: ContentItem
    @StateObject private var userPreferences = UserPreferences.shared
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Contenu principal
            Group {
                switch item.contentTypeEnum {
                case .article:
                    ArticleContentView(item: item)
                case .video:
                    VideoContentView(item: item)
                case .product:
                    ProductContentView(item: item)
                case .social:
                    SocialContentView(item: item)
                case .webpage:
                    WebpageContentView(item: item)
                case .app:
                    AppContentView(item: item)
                case .music:
                    MusicContentView(item: item)
                case .book:
                    BookContentView(item: item)
                case .travel:
                    TravelContentView(item: item)
                case .podcast:
                    PodcastContentView(item: item)
                case .show:
                    ShowContentView(item: item)
                case .image:
                    ImageContentView(item: item)
                case .text:
                    TextContentView(item: item)
                }
            }
            .blur(radius: item.isHidden ? 15 : 0, opaque: item.isHidden)
            .clipped()
            
            // URL en overlay dans le coin bas gauche
            if userPreferences.showURLs, let url = item.url, !url.isEmpty {
                Text(shortenURL(url))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary.opacity(0.7))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 4))
                    .padding(8)
                    .onTapGesture {
                        UIPasteboard.general.string = url
                        // Feedback haptique léger
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }
            }
        }
        .cornerRadius(14)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    // Le long press est géré par le contextMenu dans MainView
                    // On ne fait rien ici, juste bloquer le tap
                }
        )
        .onTapGesture {
            // Handle tap to open content
            if let urlString = item.url {
                handleContentTap(urlString: urlString)
            }
        }
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
}
