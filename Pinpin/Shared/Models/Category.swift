//
//  Category.swift
//  Pinpin
//
//  Modèle SwiftData pour les catégories
//

import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID = UUID()
    var name: String = ""
    var sortOrder: Int32 = 0
    var isDefault: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // Relation inverse avec ContentItem (optionnelle pour compatibilité CloudKit)
    @Relationship(deleteRule: .nullify, inverse: \ContentItem.category)
    var contentItems: [ContentItem]?
    
    init(
        id: UUID = UUID(),
        name: String = "",
        sortOrder: Int32 = 0,
        isDefault: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
        self.isDefault = isDefault
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.contentItems = []
    }
}

// MARK: - Extensions pour compatibilité
extension Category {
    /// Nombre d'éléments dans cette catégorie
    var itemCount: Int {
        return (contentItems ?? []).count
    }
    
    /// Vérifie si la catégorie est vide
    var isEmpty: Bool {
        return (contentItems ?? []).isEmpty
    }
}
