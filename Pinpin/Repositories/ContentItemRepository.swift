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
