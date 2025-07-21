//
//  SmartAsyncImage.swift
//  Neeed2
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
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
            } else if let remoteURL = getRemoteURL() {
                // Afficher l'image distante
                AsyncImage(url: remoteURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
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
        let potentialPaths = [
            item.metadataDict["thumbnail_url"],
            item.metadataDict["icon_url"]
        ].compactMap { $0 }.filter { $0.hasPrefix("images/") }

        for path in potentialPaths {
            if let potentialURL = SharedImageService.shared.getImageURL(from: path) as URL? {
                let pathString = potentialURL.path
                if FileManager.default.fileExists(atPath: pathString) {
                    localImageURL = potentialURL
                    break
                }
            }
        }
    }
    
    private func getRemoteURL() -> URL? {
        if let urlString = item.metadataDict["thumbnail_url"],
           !urlString.hasPrefix("images/"),
           let url = URL(string: urlString) {
            return url
        }
        return nil
    }
}
