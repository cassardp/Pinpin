//
//  ContentItem.swift
//  Pinpin
//
//  Modèle SwiftData pour les éléments de contenu
//

import Foundation
import SwiftData

@Model
final class ContentItem {
    var id: UUID = UUID()
    var title: String = "Nouveau contenu"
    var itemDescription: String?
    var url: String?
    var thumbnailUrl: String?
    var imageData: Data? // Nouvelle propriété pour stocker l'image directement
    var metadata: Data?
    var isHidden: Bool = false
    var userId: UUID?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // Relation avec Category
    var category: Category?
    
    init(
        id: UUID = UUID(),
        title: String = "Nouveau contenu",
        itemDescription: String? = nil,
        url: String? = nil,
        thumbnailUrl: String? = nil,
        imageData: Data? = nil,
        metadata: Data? = nil,
        isHidden: Bool = false,
        userId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        category: Category? = nil
    ) {
        self.id = id
        self.title = title
        self.itemDescription = itemDescription
        self.url = url
        self.thumbnailUrl = thumbnailUrl
        self.imageData = imageData
        self.metadata = metadata
        self.isHidden = isHidden
        self.userId = userId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.category = category
    }
}

// MARK: - Extensions pour compatibilité
extension ContentItem {
    /// Propriété calculée pour obtenir le meilleur titre disponible
    var bestTitle: String {
        if !title.isEmpty && title != "Nouveau contenu" {
            return title
        }
        
        if let description = itemDescription, !description.isEmpty {
            return description
        }
        
        if let url = url {
            return shortenURL(url)
        }
        
        return "Contenu sans titre"
    }
    
    /// Raccourcit une URL pour l'affichage
    private func shortenURL(_ urlString: String) -> String {
        guard let url = URL(string: urlString) else { return urlString }
        
        if let host = url.host {
            return host.replacingOccurrences(of: "www.", with: "")
        }
        
        return urlString
    }
    
    /// ID sécurisé pour éviter les crashes
    var safeId: UUID {
        return id
    }
    
    /// Dictionnaire des métadonnées pour compatibilité
    var metadataDict: [String: String] {
        guard let metadata = metadata else { return [:] }
        
        do {
            if let dict = try JSONSerialization.jsonObject(with: metadata) as? [String: Any] {
                return dict.compactMapValues { value in
                    if let stringValue = value as? String {
                        return stringValue
                    } else if let numberValue = value as? NSNumber {
                        return numberValue.stringValue
                    } else {
                        return String(describing: value)
                    }
                }
            }
        } catch {
            print("Erreur lors du parsing des métadonnées: \(error)")
        }
        
        return [:]
    }
    
    /// Nom de catégorie sécurisé pour compatibilité
    var safeCategoryName: String {
        return category?.name ?? "Général"
    }
}
