//
//  Category.swift
//  PinpinShareExtension
//
//  Modèle SwiftData pour les catégories (Share Extension)
//

import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID = UUID()
    var name: String = ""
    var colorHex: String = "#007AFF"
    var iconName: String = "folder"
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
        self.contentItems = []
    }
}
