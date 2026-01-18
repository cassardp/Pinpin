//
//  SmartAsyncImage.swift
//  Pinpin
//
//  Composant pour afficher des images depuis SwiftData ou URLs distantes
//

import SwiftUI

struct SmartAsyncImage: View {
    #if os(macOS)
    typealias PlatformImage = NSImage
    #else
    typealias PlatformImage = UIImage
    #endif

    let item: ContentItem
    let width: CGFloat?
    let height: CGFloat?
    
    @State private var imageFromData: PlatformImage?
    @State private var hasLoadedImage = false
    
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
                #if os(macOS)
                Image(nsImage: imageFromData)
                    .resizable()
                #else
                Image(uiImage: imageFromData)
                    .resizable()
                #endif
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
            // Charger une seule fois
            if !hasLoadedImage {
                loadImageFromData()
                hasLoadedImage = true
            }
        }
    }
    
    private func loadImageFromData() {
        // Charger l'image depuis SwiftData
        guard let imageData = item.imageData else { return }
        
        if let platformImage = PlatformImage(data: imageData) {
            self.imageFromData = platformImage
        }
    }
    
    private func getRemoteURL() -> URL? {
        // Vérifier uniquement thumbnailUrl pour les URLs distantes d'images
        if let thumbnailUrl = item.thumbnailUrl, 
           !thumbnailUrl.isEmpty,
           !thumbnailUrl.hasPrefix("images/"), // Ignorer les anciens chemins locaux
           !thumbnailUrl.hasPrefix("file:///var/mobile/Media/PhotoData/"), // Ignorer les fichiers temporaires iOS
           !thumbnailUrl.hasPrefix("file:///"),
           let url = URL(string: thumbnailUrl) {
            return url
        }
        
        return nil
    }
}
