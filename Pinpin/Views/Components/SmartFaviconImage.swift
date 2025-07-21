//
//  SmartFaviconImage.swift
//  Neeed2
//
//  Composant intelligent pour afficher les favicons avec fallback local/distant
//

import SwiftUI

struct SmartFaviconImage: View {
    let item: ContentItem
    let size: CGFloat
    
    @State private var localIconURL: URL?
    @State private var shouldUseRemote = false
    
    init(item: ContentItem, size: CGFloat = 20) {
        self.item = item
        self.size = size
    }
    
    var body: some View {
        Group {
            if let localURL = localIconURL, !shouldUseRemote {
                // Afficher l'icône locale
                AsyncImage(url: localURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    defaultFaviconPlaceholder
                }
                .onAppear {
                    // Vérifier si l'icône locale existe toujours
                    if !FileManager.default.fileExists(atPath: localURL.path) {
                        shouldUseRemote = true
                    }
                }
            } else if let iconUrl = item.metadataDict["icon_url"], 
                      !iconUrl.hasPrefix("images/"),
                      let remoteURL = URL(string: iconUrl) {
                // Afficher l'icône distante
                AsyncImage(url: remoteURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    defaultFaviconPlaceholder
                }
            } else {
                // Pas d'icône disponible - utiliser le placeholder
                defaultFaviconPlaceholder
            }
        }
        .frame(width: size, height: size)
        .cornerRadius(4)
        .onAppear {
            loadLocalIconIfAvailable()
        }
    }
    
    private var defaultFaviconPlaceholder: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Image(systemName: "globe")
                    .font(.system(size: size * 0.6))
                    .foregroundColor(.gray)
            )
    }
    
    private func loadLocalIconIfAvailable() {
        // Vérifier s'il y a une icône locale
        if let iconPath = item.metadataDict["icon_url"],
           iconPath.hasPrefix("images/") {
            localIconURL = SharedImageService.shared.getImageURL(from: iconPath)
        }
    }
}
