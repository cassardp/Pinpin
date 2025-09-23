//
//  DataService.swift
//  Pinpin
//
//  Service SwiftData principal pour la gestion des données
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
final class DataService: ObservableObject {
    static let shared = DataService()
    
    private let groupID = "group.com.misericode.pinpin"
    private let cloudKitContainerID = "iCloud.com.misericode.Pinpin"
    
    // MARK: - SwiftData Container
    private lazy var _container: ModelContainer = {
        prepareSharedContainerIfNeeded()
        let schema = Schema([ContentItem.self, Category.self])
        
        // Configuration pour App Group avec CloudKit (synchronisation iCloud)
        let configuration = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(groupID),
            cloudKitDatabase: .private(cloudKitContainerID)
        )
        
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            return container
        } catch {
            print("Erreur lors de la création du ModelContainer: \(error)")
            
            // Fallback vers un container en mémoire pour éviter le crash
            do {
                let fallbackConfig = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true
                )
                let fallbackContainer = try ModelContainer(for: schema, configurations: [fallbackConfig])
                print("⚠️ Utilisation d'un container en mémoire comme fallback")
                return fallbackContainer
            } catch {
                fatalError("Impossible de créer même un ModelContainer en mémoire: \(error)")
            }
        }
    }()
    
    var container: ModelContainer {
        return _container
    }
    
    var context: ModelContext {
        return _container.mainContext
    }
    
    // MARK: - State Management
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var hasMoreItems = true
    
    private let itemsPerPage = 50
    private var currentLimit = 50
    
    private init() {
        createDefaultCategoriesIfNeeded()
    }
    
    // MARK: - Content Items Management
    func loadContentItems() -> [ContentItem] {
        isLoading = true
        errorMessage = nil
        currentLimit = itemsPerPage
        
        let descriptor = FetchDescriptor<ContentItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let items = try context.fetch(descriptor)
            let unique = uniqueItems(items)
            checkForMoreItems(currentCount: unique.count)
            isLoading = false
            return Array(unique.prefix(currentLimit))
        } catch {
            errorMessage = "Erreur de chargement: \(error.localizedDescription)"
            isLoading = false
            return []
        }
    }
    
    func loadMoreContentItems() -> [ContentItem] {
        guard !isLoadingMore && hasMoreItems else { return [] }
        
        isLoadingMore = true
        currentLimit += itemsPerPage
        
        let descriptor = FetchDescriptor<ContentItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let items = try context.fetch(descriptor)
            let unique = uniqueItems(items)
            checkForMoreItems(currentCount: unique.count)
            isLoadingMore = false
            return Array(unique.prefix(currentLimit))
        } catch {
            errorMessage = "Erreur de chargement: \(error.localizedDescription)"
            isLoadingMore = false
            return []
        }
    }
    
    private func checkForMoreItems(currentCount: Int) {
        hasMoreItems = currentCount > currentLimit
    }
    
    func addContentItem(_ item: ContentItem) {
        context.insert(item)
        save()
    }
    
    func saveContentItem(
        categoryName: String,
        title: String,
        description: String? = nil,
        url: String? = nil,
        metadata: [String: String] = [:],
        thumbnailUrl: String? = nil
    ) {
        // Trouver ou créer la catégorie
        let category = findOrCreateCategory(name: categoryName)
        
        // Convertir metadata en Data
        var metadataData: Data? = nil
        if !metadata.isEmpty {
            do {
                metadataData = try JSONSerialization.data(withJSONObject: metadata)
            } catch {
                print("Erreur lors de la sérialisation des métadonnées: \(error)")
            }
        }
        
        let newItem = ContentItem(
            title: title,
            itemDescription: description,
            url: url,
            thumbnailUrl: thumbnailUrl,
            metadata: metadataData,
            category: category
        )
        
        context.insert(newItem)
        save()
    }
    
    func updateContentItem(_ item: ContentItem) {
        item.updatedAt = Date()
        save()
    }
    
    func deleteContentItem(_ item: ContentItem) {
        context.delete(item)
        save()
    }
    
    func deleteContentItems(_ items: [ContentItem]) {
        for item in items {
            context.delete(item)
        }
        save()
    }
    
    func updateContentItem(_ item: ContentItem, categoryName: String) {
        let category = findOrCreateCategory(name: categoryName)
        item.category = category
        item.updatedAt = Date()
        save()
    }
    
    func updateContentItem(_ item: ContentItem, isHidden: Bool) {
        item.isHidden = isHidden
        item.updatedAt = Date()
        save()
    }
    
    // MARK: - Category Management
    func fetchCategories() -> [Category] {
        let descriptor = FetchDescriptor<Category>(
            sortBy: [SortDescriptor(\.sortOrder, order: .forward)]
        )
        
        do {
            let categories = try context.fetch(descriptor)
            return categories
        } catch {
            print("Erreur lors de la récupération des catégories: \(error)")
            return []
        }
    }
    
    func fetchCategoryNames() -> [String] {
        var seen = Set<UUID>()
        return fetchCategories().compactMap { category in
            guard seen.insert(category.id).inserted else { return nil }
            return category.name
        }
    }
    
    func addCategory(name: String, colorHex: String = "#007AFF", iconName: String = "folder") {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // Vérifier que le nom n'existe pas déjà
        let existingCategories = fetchCategories()
        if existingCategories.contains(where: { $0.name == trimmedName }) {
            return
        }
        
        let category = Category(
            name: trimmedName,
            colorHex: colorHex,
            iconName: iconName,
            sortOrder: Int32(existingCategories.count),
            isDefault: existingCategories.isEmpty
        )
        
        context.insert(category)
        save()
    }
    
    func getDefaultCategoryName() -> String {
        let categories = fetchCategories()
        return categories.first(where: { $0.isDefault })?.name ?? "Général"
    }
    
    private func createDefaultCategoriesIfNeeded() {
        let categories = fetchCategories()
        if categories.isEmpty {
            // Pas de catégories par défaut au premier lancement
            // L'utilisateur devra créer ses propres catégories
        }
    }
    
    // MARK: - Helper Methods
    
    /// Trouve ou crée une catégorie par nom
    private func findOrCreateCategory(name: String) -> Category {
        // Chercher la catégorie existante
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { $0.name == name }
        )
        
        do {
            let categories = try context.fetch(descriptor)
            if let existingCategory = categories.first {
                return existingCategory
            }
        } catch {
            print("Erreur lors de la recherche de catégorie: \(error)")
        }
        
        // Créer une nouvelle catégorie si elle n'existe pas
        let existingCategories = fetchCategories()
        let newCategory = Category(
            name: name,
            sortOrder: Int32(existingCategories.count),
            isDefault: existingCategories.isEmpty
        )
        
        context.insert(newCategory)
        return newCategory
    }
    
    private func uniqueItems(_ items: [ContentItem]) -> [ContentItem] {
        var seen = Set<UUID>()
        return items.filter { seen.insert($0.id).inserted }
    }
    
    private func prepareSharedContainerIfNeeded() {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) else {
            print("[DataService] Impossible d'accéder au container partagé")
            return
        }
        let libraryURL = containerURL.appendingPathComponent("Library", isDirectory: true)
        let supportURL = libraryURL.appendingPathComponent("Application Support", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: supportURL, withIntermediateDirectories: true)
        } catch {
            print("[DataService] Erreur lors de la préparation du container partagé: \(error)")
        }
    }
    
    // MARK: - Search and Filter
    func searchContentItems(query: String) -> [ContentItem] {
        guard !query.isEmpty else { return loadContentItems() }
        
        let descriptor = FetchDescriptor<ContentItem>(
            predicate: #Predicate { item in
                item.title.localizedStandardContains(query) ||
                (item.itemDescription?.localizedStandardContains(query) ?? false) ||
                (item.url?.localizedStandardContains(query) ?? false)
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let items = try context.fetch(descriptor)
            return uniqueItems(items)
        } catch {
            print("Erreur lors de la recherche: \(error)")
            return []
        }
    }
    
    func filterContentItems(by categoryName: String) -> [ContentItem] {
        let descriptor = FetchDescriptor<ContentItem>(
            predicate: #Predicate { item in
                item.category?.name == categoryName
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let items = try context.fetch(descriptor)
            return uniqueItems(items)
        } catch {
            print("Erreur lors du filtrage: \(error)")
            return []
        }
    }
    
    func fetchFirstImageURL(for categoryName: String) -> String? {
        var descriptor = FetchDescriptor<ContentItem>(
            predicate: #Predicate { item in
                item.category?.name == categoryName && item.thumbnailUrl != nil
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        
        do {
            let items = try context.fetch(descriptor)
            return items.first?.thumbnailUrl
        } catch {
            print("Erreur lors de la récupération de la première image: \(error)")
            return nil
        }
    }
    
    func getRandomItemForCategory(_ categoryName: String) -> ContentItem? {
        let descriptor = FetchDescriptor<ContentItem>(
            predicate: #Predicate { $0.category?.name == categoryName }
        )
        
        do {
            let items = try context.fetch(descriptor)
            return uniqueItems(items).randomElement()
        } catch {
            print("Erreur lors de la récupération d'un item aléatoire: \(error)")
            return nil
        }
    }
    
    func countItems(for categoryName: String) -> Int {
        let descriptor = FetchDescriptor<ContentItem>(
            predicate: #Predicate { $0.category?.name == categoryName }
        )
        
        do {
            let items = try context.fetch(descriptor)
            return uniqueItems(items).count
        } catch {
            print("Erreur lors du comptage des items: \(error)")
            return 0
        }
    }
    
    func getItemCountForCategory(_ categoryName: String) -> Int {
        return countItems(for: categoryName)
    }
    
    // MARK: - Save Context
    func save() {
        do {
            try context.save()
        } catch {
            print("Erreur lors de la sauvegarde: \(error)")
            errorMessage = "Erreur de sauvegarde: \(error.localizedDescription)"
        }
    }
}
