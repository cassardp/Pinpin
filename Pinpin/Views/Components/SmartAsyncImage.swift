//
//  SmartAsyncImage.swift
//  Pinpin
//
//  Composant pour afficher des images depuis SwiftData ou URLs distantes
//

import SwiftUI

struct SmartAsyncImage: View {
    let item: ContentItem
    let width: CGFloat?
    let height: CGFloat?
    
    @State private var imageFromData: UIImage?
    
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
            if let imageFromData = imageFromData {
                // Priorité 1: Image depuis SwiftData
                Image(uiImage: imageFromData)
                    .resizable()
            } else if let remoteURL = getRemoteURL() {
                // Priorité 2: Image distante
                AsyncImage(url: remoteURL) { image in
                    image
                        .resizable()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
            } else {
                // Placeholder par défaut
                Color.gray.opacity(0.3)
            }
        }
        .onAppear {
            loadImageFromData()
        }
    }
    
    private func loadImageFromData() {
        // Charger l'image depuis SwiftData
        guard let imageData = item.imageData else { return }
        
        if let uiImage = UIImage(data: imageData) {
            self.imageFromData = uiImage
        }
    }
    
    private func getRemoteURL() -> URL? {
        // Vérifier d'abord thumbnailUrl pour les URLs distantes
        if let thumbnailUrl = item.thumbnailUrl, 
           !thumbnailUrl.isEmpty,
           !thumbnailUrl.hasPrefix("images/"), // Ignorer les anciens chemins locaux
           let url = URL(string: thumbnailUrl) {
            return url
        }
        
        // Fallback vers l'URL principale
        if let urlString = item.url, let url = URL(string: urlString) {
            return url
        }
        
        return nil
    }
}
