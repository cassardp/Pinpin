//
//  ContentItemRepository.swift
//  Pinpin
//
//  Repository pour la gestion des ContentItems
//

import Foundation
import SwiftData

@MainActor
final class ContentItemRepository {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    // MARK: - CRUD Operations
    
    func insert(_ item: ContentItem) {
        context.insert(item)
    }
    
    func delete(_ item: ContentItem) {
        context.delete(item)
    }
    
    func delete(_ items: [ContentItem]) {
        for item in items {
            context.delete(item)
        }
    }
    
    func update(_ item: ContentItem) {
        item.updatedAt = Date()
    }

    func updateCategory(_ item: ContentItem, category: Category?) {
        item.category = category
        update(item)
    }

    func updateCategories(_ items: [ContentItem], category: Category?) {
        for item in items {
            updateCategory(item, category: category)
        }
    }

    func updateTitle(_ item: ContentItem, title: String) {
        item.title = title
        update(item)
    }

    func fetchById(_ id: UUID) throws -> ContentItem? {
        let descriptor = FetchDescriptor<ContentItem>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    /// Vérifie si un item identique (même title + url) a été créé dans les dernières secondes
    /// Utilisé pour éviter les doublons lors de clics/taps rapides
    func fetchRecentDuplicate(title: String, url: String?, withinSeconds: TimeInterval = 2.0) throws -> ContentItem? {
        let cutoffDate = Date().addingTimeInterval(-withinSeconds)

        // Cas 1: Item avec URL
        if let url = url, !url.isEmpty {
            let descriptor = FetchDescriptor<ContentItem>(
                predicate: #Predicate { item in
                    item.title == title &&
                    item.url == url &&
                    item.createdAt >= cutoffDate
                },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            return try context.fetch(descriptor).first
        }

        // Cas 2: Item sans URL (notes textuelles)
        let descriptor = FetchDescriptor<ContentItem>(
            predicate: #Predicate { item in
                item.title == title &&
                (item.url == nil || item.url == "") &&
                item.createdAt >= cutoffDate
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor).first
    }

    func upsert(id: UUID, userId: UUID?, categoryName: String?, title: String, itemDescription: String?, url: String?, metadata: Data?, thumbnailUrl: String?, imageData: Data?, isHidden: Bool, createdAt: Date?, updatedAt: Date?) throws -> ContentItem {
        // Chercher par ID
        if let existing = try fetchById(id) {
            // Mettre à jour
            existing.userId = userId ?? existing.userId
            existing.title = title
            existing.itemDescription = itemDescription
            existing.url = url
            existing.metadata = metadata
            existing.thumbnailUrl = thumbnailUrl
            existing.imageData = imageData
            existing.isHidden = isHidden
            existing.createdAt = createdAt ?? existing.createdAt
            existing.updatedAt = Date()
            return existing
        }

        // Créer nouveau
        let item = ContentItem()
        item.id = id
        item.userId = userId
        item.title = title
        item.itemDescription = itemDescription
        item.url = url
        item.metadata = metadata
        item.thumbnailUrl = thumbnailUrl
        item.imageData = imageData
        item.isHidden = isHidden
        item.createdAt = createdAt ?? Date()
        item.updatedAt = Date()

        insert(item)
        return item
    }

    // MARK: - Fetch Operations
    
    func fetchAll(limit: Int? = nil) throws -> [ContentItem] {
        var descriptor = FetchDescriptor<ContentItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        if let limit = limit {
            descriptor.fetchLimit = limit
        }
        return try context.fetch(descriptor)
    }
    
    func fetchByCategory(_ categoryName: String) throws -> [ContentItem] {
        let descriptor = FetchDescriptor<ContentItem>(
            predicate: #Predicate { item in
                item.category?.name == categoryName
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
    
    func search(query: String) throws -> [ContentItem] {
        let descriptor = FetchDescriptor<ContentItem>(
            predicate: #Predicate { item in
                item.title.localizedStandardContains(query) ||
                (item.itemDescription?.localizedStandardContains(query) ?? false) ||
                (item.url?.localizedStandardContains(query) ?? false)
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
    
    func fetchFirstImageURL(for categoryName: String) throws -> String? {
        var descriptor = FetchDescriptor<ContentItem>(
            predicate: #Predicate { item in
                item.category?.name == categoryName && item.thumbnailUrl != nil
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        let items = try context.fetch(descriptor)
        return items.first?.thumbnailUrl
    }

    func fetchFirstImageData(for categoryName: String) throws -> Data? {
        var descriptor = FetchDescriptor<ContentItem>(
            predicate: #Predicate { item in
                item.category?.name == categoryName && item.imageData != nil
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        let items = try context.fetch(descriptor)
        return uniqueItems(items).first?.imageData
    }
    
    func fetchRandom(for categoryName: String) throws -> ContentItem? {
        let descriptor = FetchDescriptor<ContentItem>(
            predicate: #Predicate { $0.category?.name == categoryName }
        )
        let items = try context.fetch(descriptor)
        return uniqueItems(items).randomElement()
    }
    
    func count(for categoryName: String) throws -> Int {
        let descriptor = FetchDescriptor<ContentItem>(
            predicate: #Predicate { $0.category?.name == categoryName }
        )
        let items = try context.fetch(descriptor)
        return uniqueItems(items).count
    }
    
    // MARK: - Maintenance
    
    func cleanupInvalidImageURLs() throws {
        let allItems = try fetchAll()
        var cleanedCount = 0
        
        for item in allItems {
            var needsUpdate = false
            
            // Nettoyer thumbnailUrl si c'est un fichier temporaire iOS
            if let thumbnailUrl = item.thumbnailUrl,
               (thumbnailUrl.hasPrefix("file:///var/mobile/Media/PhotoData/") ||
                thumbnailUrl.hasPrefix("file:///private/var/mobile/Media/PhotoData/")) {
                item.thumbnailUrl = nil
                needsUpdate = true
            }
            
            // Nettoyer url si c'est un fichier temporaire iOS
            if let url = item.url,
               (url.hasPrefix("file:///var/mobile/Media/PhotoData/") ||
                url.hasPrefix("file:///private/var/mobile/Media/PhotoData/")) {
                item.url = nil
                needsUpdate = true
            }
            
            if needsUpdate {
                cleanedCount += 1
            }
        }
        
        if cleanedCount > 0 {
            print("[ContentItemRepository] Nettoyage terminé: \(cleanedCount) items mis à jour")
        }
    }
    
    // MARK: - Helper Methods
    
    private func uniqueItems(_ items: [ContentItem]) -> [ContentItem] {
        var seen = Set<UUID>()
        return items.filter { seen.insert($0.id).inserted }
    }
}
