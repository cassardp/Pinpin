//
//  DataService.swift
//  Pinpin
//
//  Service SwiftData principal - Refactorisé avec repositories
//

import Foundation
import SwiftData
import Combine

@MainActor
final class DataService: ObservableObject {
    static let shared = DataService()
    
    // MARK: - SwiftData Container
    private lazy var _container: ModelContainer = {
        MaintenanceService.shared.prepareSharedContainer()
        let schema = Schema([ContentItem.self, Category.self])
        
        let configuration = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(AppConstants.groupID),
            cloudKitDatabase: .private(AppConstants.cloudKitContainerID)
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            print("[DataService] ❌ Erreur création ModelContainer: \(error)")
            
            // Fallback en mémoire
            do {
                let fallbackConfig = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true
                )
                print("[DataService] ⚠️ Utilisation container en mémoire")
                return try ModelContainer(for: schema, configurations: [fallbackConfig])
            } catch {
                fatalError("Impossible de créer ModelContainer: \(error)")
            }
        }
    }()
    
    var container: ModelContainer {
        _container
    }
    
    var context: ModelContext {
        _container.mainContext
    }

    // MARK: - Repositories
    private lazy var contentItemRepository = ContentItemRepository(context: context)
    private lazy var categoryRepository = CategoryRepository(context: context)

    // MARK: - Services
    // Note: CloudSyncService est conservé uniquement pour l'affichage du statut dans SettingsView
    // SwiftData avec .automatic gère la vraie synchronisation CloudKit
    let cloudSyncService = CloudSyncService()
    
    // MARK: - State Management
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var hasMoreItems = true
    
    private let itemsPerPage = AppConstants.itemsPerPage
    private var currentLimit = 50
    
    // MARK: - iCloud Sync (délégué à CloudSyncService)
    var isSyncing: Bool {
        cloudSyncService.isSyncing
    }
    
    var lastSyncDate: Date? {
        cloudSyncService.lastSyncDate
    }
    
    var isiCloudAvailable: Bool {
        cloudSyncService.isAvailable
    }
    
    private init() {
        // Pas de catégories par défaut
    }
    
    // MARK: - Content Items Management
    
    func loadContentItems() -> [ContentItem] {
        isLoading = true
        errorMessage = nil
        currentLimit = itemsPerPage
        
        defer { isLoading = false }
        
        do {
            let items = try contentItemRepository.fetchAll(limit: currentLimit + 1)
            updatePaginationState(totalFetched: items.count, limit: currentLimit)
            return Array(items.prefix(currentLimit))
        } catch {
            errorMessage = "Erreur de chargement: \(error.localizedDescription)"
            print("[DataService] ❌ \(error)")
            return []
        }
    }
    
    func loadMoreContentItems() -> [ContentItem] {
        guard !isLoadingMore && hasMoreItems else { return [] }
        
        isLoadingMore = true
        currentLimit += itemsPerPage
        
        defer { isLoadingMore = false }
        
        do {
            let items = try contentItemRepository.fetchAll(limit: currentLimit + 1)
            updatePaginationState(totalFetched: items.count, limit: currentLimit)
            return Array(items.prefix(currentLimit))
        } catch {
            errorMessage = "Erreur de chargement: \(error.localizedDescription)"
            print("[DataService] ❌ \(error)")
            return []
        }
    }
    
    func addContentItem(_ item: ContentItem) {
        contentItemRepository.insert(item)
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
        saveContentItemWithImageData(
            categoryName: categoryName,
            title: title,
            description: description,
            url: url,
            metadata: metadata,
            thumbnailUrl: thumbnailUrl,
            imageData: nil
        )
    }
    
    func saveContentItemWithImageData(
        categoryName: String,
        title: String,
        description: String? = nil,
        url: String? = nil,
        metadata: [String: String] = [:],
        thumbnailUrl: String? = nil,
        imageData: Data? = nil
    ) {
        do {
            let category = try categoryRepository.findOrCreate(name: categoryName)
            
            let newItem = ContentItem(
                title: title,
                itemDescription: description,
                url: url,
                thumbnailUrl: thumbnailUrl,
                imageData: imageData,
                metadata: MaintenanceService.shared.encodeMetadata(metadata),
                category: category
            )
            
            contentItemRepository.insert(newItem)
            save()
        } catch {
            print("[DataService] ❌ Erreur saveContentItem: \(error)")
        }
    }
    
    func updateContentItem(_ item: ContentItem) {
        contentItemRepository.update(item)
        save()
    }
    
    func deleteContentItem(_ item: ContentItem) {
        contentItemRepository.delete(item)
        save()
    }
    
    func deleteContentItems(_ items: [ContentItem]) {
        contentItemRepository.delete(items)
        save()
    }
    
    func updateContentItem(_ item: ContentItem, categoryName: String) {
        do {
            let category = try categoryRepository.findOrCreate(name: categoryName)
            item.category = category
            contentItemRepository.update(item)
            save()
        } catch {
            print("[DataService] ❌ Erreur updateContentItem: \(error)")
        }
    }
    
    func updateContentItem(_ item: ContentItem, isHidden: Bool) {
        item.isHidden = isHidden
        contentItemRepository.update(item)
        save()
    }
    
    // MARK: - Category Management
    
    func fetchCategories() -> [Category] {
        do {
            return try categoryRepository.fetchAll()
        } catch {
            print("[DataService] ❌ Erreur fetchCategories: \(error)")
            return []
        }
    }
    
    func fetchCategoryNames() -> [String] {
        do {
            return try categoryRepository.fetchNames()
        } catch {
            print("[DataService] ❌ Erreur fetchCategoryNames: \(error)")
            return []
        }
    }
    
    func addCategory(name: String, colorHex: String = "#007AFF", iconName: String = "folder") {
        do {
            try categoryRepository.create(name: name, colorHex: colorHex, iconName: iconName)
            save()
        } catch {
            print("[DataService] ❌ Erreur addCategory: \(error)")
        }
    }
    
    func getDefaultCategoryName() -> String {
        do {
            return try categoryRepository.getDefaultCategoryName()
        } catch {
            return AppConstants.defaultCategoryName
        }
    }
    
    func deleteCategory(_ category: Category) {
        do {
            // Récupérer les items avant suppression
            let itemsToReassign = category.contentItems ?? []
            
            if !itemsToReassign.isEmpty {
                let miscCategory = try categoryRepository.findOrCreateMiscCategory()
                
                for item in itemsToReassign {
                    item.category = miscCategory
                    contentItemRepository.update(item)
                }
            }
            
            categoryRepository.delete(category)
            save()
        } catch {
            print("[DataService] ❌ Erreur deleteCategory: \(error)")
        }
    }
    
    func cleanupEmptyMiscCategory() {
        do {
            try categoryRepository.cleanupEmptyMiscCategories()
            save()
        } catch {
            print("[DataService] ❌ Erreur cleanupEmptyMiscCategory: \(error)")
        }
    }
    
    func createDefaultCategories() {
        print("[DataService] 🎨 Création des catégories par défaut...")
        
        for categoryName in AppConstants.defaultCategories {
            addCategory(name: categoryName)
        }
        
        print("[DataService] ✅ \(AppConstants.defaultCategories.count) catégories créées")
    }
    
    // MARK: - Search and Filter
    
    func searchContentItems(query: String) -> [ContentItem] {
        guard !query.isEmpty else { return loadContentItems() }
        
        do {
            return try contentItemRepository.search(query: query)
        } catch {
            print("[DataService] ❌ Erreur search: \(error)")
            return []
        }
    }
    
    func filterContentItems(by categoryName: String) -> [ContentItem] {
        do {
            return try contentItemRepository.fetchByCategory(categoryName)
        } catch {
            print("[DataService] ❌ Erreur filter: \(error)")
            return []
        }
    }
    
    func fetchFirstImageURL(for categoryName: String) -> String? {
        do {
            return try contentItemRepository.fetchFirstImageURL(for: categoryName)
        } catch {
            print("[DataService] ❌ Erreur fetchFirstImageURL: \(error)")
            return nil
        }
    }
    
    func getRandomItemForCategory(_ categoryName: String) -> ContentItem? {
        do {
            return try contentItemRepository.fetchRandom(for: categoryName)
        } catch {
            print("[DataService] ❌ Erreur getRandomItem: \(error)")
            return nil
        }
    }
    
    func countItems(for categoryName: String) -> Int {
        do {
            return try contentItemRepository.count(for: categoryName)
        } catch {
            print("[DataService] ❌ Erreur countItems: \(error)")
            return 0
        }
    }
    
    func getItemCountForCategory(_ categoryName: String) -> Int {
        return countItems(for: categoryName)
    }
    
    // MARK: - Maintenance
    
    func cleanupInvalidImageURLs() {
        do {
            try contentItemRepository.cleanupInvalidImageURLs()
            save()
        } catch {
            print("[DataService] ❌ Erreur cleanup: \(error)")
        }
    }
    
    // MARK: - iCloud Sync Methods (délégués)
    
    func isiCloudSyncUpToDate() -> Bool {
        cloudSyncService.isUpToDate()
    }
    
    func getiCloudSyncStatus() -> String {
        cloudSyncService.getStatusText()
    }
    
    // MARK: - Save Context
    
    func save() {
        do {
            try context.save()
        } catch {
            print("[DataService] ❌ Erreur save: \(error)")
            errorMessage = "Erreur de sauvegarde: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Private Helpers
    
    private func updatePaginationState(totalFetched: Int, limit: Int) {
        hasMoreItems = totalFetched > limit
    }
    
    private func prepareSharedContainerIfNeeded() {
        MaintenanceService.shared.prepareSharedContainer()
    }
}
