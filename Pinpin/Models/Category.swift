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
    var id: UUID
    var name: String
    var colorHex: String
    var iconName: String
    var sortOrder: Int32
    var isDefault: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // Relation inverse avec ContentItem
    @Relationship(deleteRule: .nullify, inverse: \ContentItem.category)
    var contentItems: [ContentItem] = []
    
    init(
        id: UUID = UUID(),
        name: String = "",
        colorHex: String = "#007AFF",
        iconName: String = "folder",
        sortOrder: Int32 = 0,
        isDefault: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
        self.sortOrder = sortOrder
        self.isDefault = isDefault
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Extensions pour compatibilité
extension Category {
    /// Nombre d'éléments dans cette catégorie
    var itemCount: Int {
        return contentItems.count
    }
    
    /// Vérifie si la catégorie est vide
    var isEmpty: Bool {
        return contentItems.isEmpty
    }
}
