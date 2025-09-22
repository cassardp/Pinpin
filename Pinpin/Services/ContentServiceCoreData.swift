//
//  ContentServiceCoreData.swift
//  Pinpin
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
        categoryName: String,
        title: String,
        description: String? = nil,
        url: String? = nil,
        metadata: [String: String] = [:],
        thumbnailUrl: String? = nil
    ) {
        let newItem = ContentItem(context: coreDataService.context)
        
        newItem.id = UUID()
        newItem.userId = currentUserId
        
        // Trouver ou créer la catégorie
        let category = findOrCreateCategory(name: categoryName)
        newItem.category = category
        
        newItem.title = title
        newItem.itemDescription = description
        newItem.url = url
        newItem.metadata = metadata as NSDictionary
        newItem.thumbnailUrl = thumbnailUrl
        newItem.isHidden = false
        
        let now = Date()
        newItem.createdAt = now
        newItem.updatedAt = now
        
        coreDataService.save()
        loadContentItems()
    }
    
    func deleteContentItem(_ item: ContentItem) {
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
    
    func updateContentItem(_ item: ContentItem, categoryName: String) {
        let category = findOrCreateCategory(name: categoryName)
        item.category = category
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
    
    // MARK: - Category Methods
    
    /// Trouve ou crée une catégorie par nom
    private func findOrCreateCategory(name: String) -> Category {
        // Chercher la catégorie existante
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        request.fetchLimit = 1
        
        do {
            if let existingCategory = try coreDataService.context.fetch(request).first {
                return existingCategory
            }
        } catch {
            print("Erreur lors de la recherche de catégorie: \(error)")
        }
        
        // Créer une nouvelle catégorie si elle n'existe pas
        let newCategory = Category(context: coreDataService.context)
        newCategory.id = UUID()
        newCategory.name = name
        newCategory.colorHex = "#007AFF"
        newCategory.iconName = "folder"
        newCategory.sortOrder = Int32(coreDataService.fetchCategories().count)
        newCategory.isDefault = false
        let now = Date()
        newCategory.createdAt = now
        newCategory.updatedAt = now
        
        return newCategory
    }
    
    /// Récupère un item aléatoire d'une catégorie pour l'affichage en miniature
    func getRandomItemForCategory(_ categoryName: String) -> ContentItem? {
        let request: NSFetchRequest<ContentItem> = ContentItem.fetchRequest()
        request.predicate = NSPredicate(format: "category.name == %@", categoryName)
        request.fetchLimit = 10 // Récupère les 10 derniers pour avoir du choix
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ContentItem.createdAt, ascending: false)]
        
        do {
            let items = try coreDataService.context.fetch(request)
            return items.randomElement()
        } catch {
            print("Erreur lors de la récupération d'un item aléatoire: \(error)")
            return nil
        }
    }
    
    /// Compte le nombre d'items dans une catégorie
    func getItemCountForCategory(_ categoryName: String) -> Int {
        let request: NSFetchRequest<ContentItem> = ContentItem.fetchRequest()
        request.predicate = NSPredicate(format: "category.name == %@", categoryName)
        
        do {
            return try coreDataService.context.count(for: request)
        } catch {
            print("Erreur lors du comptage des items: \(error)")
            return 0
        }
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
    var safeCategoryName: String {
        return category?.name ?? "Général"
    }
}
