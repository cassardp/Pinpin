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
                    placeholderView
                }
            } else {
                // Placeholder par défaut
                placeholderView
            }
        }
        .task {
            // Decode image OFF main thread (iOS 18 best practice)
            guard let imageData = item.imageData else { return }
            
            // Petit délai aléatoire pour étaler la charge CPU au démarrage
            // Évite le spike quand 20-30 images se décodent en même temps
            try? await Task.sleep(nanoseconds: UInt64.random(in: 0...20_000_000)) // 0-20ms
            
            imageFromData = await Task.detached {
                UIImage(data: imageData)
            }.value
        }
        .onDisappear {
            // Libère la RAM quand l'image sort du viewport
            // LazyVStack ne recycle pas, donc on doit le faire manuellement
            imageFromData = nil
        }
    }
    
    // MARK: - Placeholder View
    
    private var placeholderView: some View {
        Color(white: 0.95)
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
