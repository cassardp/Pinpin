//
//  ContentServiceCoreData.swift
//  Neeed2
//
//  Service Core Data simple
//

import Foundation
import CoreData

@MainActor
class ContentServiceCoreData: ObservableObject {
    @Published var contentItems: [ContentItem] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var hasMoreItems = true
    
    private let coreDataService = CoreDataService.shared
    private var currentUserId: UUID = UUID()
    private let itemsPerPage = 50
    private var currentLimit = 50
    
    init() {
        loadContentItems()
    }
    
    // MARK: - Content Items
    func loadContentItems() {
        isLoading = true
        errorMessage = nil
        currentLimit = itemsPerPage // Reset à la première page
        
        let request: NSFetchRequest<ContentItem> = ContentItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ContentItem.createdAt, ascending: false)]
        request.fetchLimit = currentLimit
        
        do {
            contentItems = try coreDataService.context.fetch(request)
            checkForMoreItems()
        } catch {
            errorMessage = "Erreur de chargement: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadMoreContentItems() {
        guard !isLoadingMore && hasMoreItems else { return }
        
        isLoadingMore = true
        currentLimit += itemsPerPage
        
        let request: NSFetchRequest<ContentItem> = ContentItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ContentItem.createdAt, ascending: false)]
        request.fetchLimit = currentLimit
        
        do {
            contentItems = try coreDataService.context.fetch(request)
            checkForMoreItems()
        } catch {
            errorMessage = "Erreur de chargement: \(error.localizedDescription)"
        }
        
        isLoadingMore = false
    }
    
    private func checkForMoreItems() {
        // Vérifier s'il y a plus d'items à charger
        let totalRequest: NSFetchRequest<ContentItem> = ContentItem.fetchRequest()
        do {
            let totalCount = try coreDataService.context.count(for: totalRequest)
            hasMoreItems = contentItems.count < totalCount
        } catch {
            hasMoreItems = false
        }
    }
    
    func saveContentItem(
        contentType: String,
        title: String,
        description: String? = nil,
        url: String? = nil,
        metadata: [String: String]? = nil,
        thumbnailUrl: String? = nil
    ) {
        let context = coreDataService.context
        let newItem = ContentItem(context: context)
        
        newItem.id = UUID()
        newItem.userId = currentUserId
        newItem.contentType = contentType
        newItem.title = title
        newItem.itemDescription = description
        newItem.url = url
        newItem.metadata = metadata as NSObject?
        newItem.thumbnailUrl = thumbnailUrl
        newItem.createdAt = Date()
        newItem.updatedAt = Date()
        
        coreDataService.save()
        loadContentItems()
    }
    
    func deleteContentItem(_ item: ContentItem) {
        // Supprimer les images associées avant de supprimer l'item
        SharedImageService.shared.deleteImagesForItem(item)
        
        let context = coreDataService.context
        context.delete(item)
        coreDataService.save()
        loadContentItems()
    }
    
    func updateContentItem(_ item: ContentItem) {
        item.updatedAt = Date()
        coreDataService.save()
        loadContentItems()
    }
    
    func updateContentItem(_ item: ContentItem, contentType: String) {
        item.contentType = contentType
        item.updatedAt = Date()
        coreDataService.save()
        loadContentItems()
    }
    
    func updateContentItem(_ item: ContentItem, isHidden: Bool) {
        item.isHidden = isHidden
        item.updatedAt = Date()
        coreDataService.save()
        loadContentItems()
    }
}

// MARK: - ContentItem Extensions
extension ContentItem {
    
    // Propriétés sécurisées pour les optionnels
    var safeCreatedAt: Date {
        return createdAt ?? Date()
    }
    
    var safeUpdatedAt: Date {
        return updatedAt ?? Date()
    }
    
    var safeId: UUID {
        return id ?? UUID()
    }
    
    var safeUserId: UUID {
        return userId ?? UUID()
    }
    
    // Propriété pour accéder facilement aux metadata
    var metadataDict: [String: String] {
        return metadata as? [String: String] ?? [:]
    }
    
    // Catégorie de contenu
    var safeContentType: String {
        return contentType ?? ""
    }
}
