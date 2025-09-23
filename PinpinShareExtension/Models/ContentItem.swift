//
//  ContentItem.swift
//  PinpinShareExtension
//
//  Modèle SwiftData pour les éléments de contenu (Share Extension)
//

import Foundation
import SwiftData

@Model
final class ContentItem {
    var id: UUID
    var title: String
    var itemDescription: String?
    var url: String?
    var thumbnailUrl: String?
    var metadata: Data?
    var isHidden: Bool
    var userId: UUID?
    var createdAt: Date
    var updatedAt: Date
    
    // Relation avec Category
    var category: Category?
    
    init(
        id: UUID = UUID(),
        title: String = "Nouveau contenu",
        itemDescription: String? = nil,
        url: String? = nil,
        thumbnailUrl: String? = nil,
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
        self.metadata = metadata
        self.isHidden = isHidden
        self.userId = userId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.category = category
    }
}
