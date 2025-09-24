//
//  SmartAsyncImage.swift
//  Pinpin
//
//  Composant intelligent pour afficher des images avec fallback local/distant
//

import SwiftUI

struct SmartAsyncImage: View {
    let item: ContentItem
    let width: CGFloat?
    let height: CGFloat?
    
    @State private var localImageURL: URL?
    
    init(
        item: ContentItem,
        width: CGFloat? = nil,
        height: CGFloat? = nil
    ) {
        self.item = item
        self.width = width
        self.height = height
    }
    
    var body: some View {
        Group {
            if let localURL = localImageURL, FileManager.default.fileExists(atPath: localURL.path) {
                // Afficher l'image locale
                AsyncImage(url: localURL) { image in
                    image
                        .resizable()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
            } else if let remoteURL = getRemoteURL() {
                // Afficher l'image distante
                AsyncImage(url: remoteURL) { image in
                    image
                        .resizable()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
            } else {
                // Aucun fallback
                Color.gray.opacity(0.3)
            }
        }
        .onAppear {
            loadLocalImageIfAvailable()
        }
    }
    
    private func loadLocalImageIfAvailable() {
        // Utiliser directement thumbnailUrl de l'item
        guard let thumbnailUrl = item.thumbnailUrl, !thumbnailUrl.isEmpty else { return }
        
        if thumbnailUrl.hasPrefix("images/") {
            // Image locale
            if let potentialURL = SharedImageService.shared.getImageURL(from: thumbnailUrl) as URL? {
                let pathString = potentialURL.path
                if FileManager.default.fileExists(atPath: pathString) {
                    localImageURL = potentialURL
                }
            }
        }
    }
    
    private func getRemoteURL() -> URL? {
        // Utiliser directement thumbnailUrl de l'item
        guard let thumbnailUrl = item.thumbnailUrl, !thumbnailUrl.isEmpty else {
            // Fallback vers l'URL principale si pas de thumbnail
            if let urlString = item.url, let url = URL(string: urlString) {
                return url
            }
            return nil
        }
        
        if !thumbnailUrl.hasPrefix("images/"), let url = URL(string: thumbnailUrl) {
            return url
        }
        
        return nil
    }
}
