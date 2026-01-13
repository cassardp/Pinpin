//
//  CoreDataService.swift
//  Pinpin
//
//  Service Core Data avec CloudKit et App Group pour partage avec Share Extension
//

import Foundation
import CoreData
import CloudKit

@MainActor
class CoreDataService: ObservableObject {
    static let shared = CoreDataService()
    
    private let groupID = "group.com.misericode.pinpin"
    
    // MARK: - Initialization
    private init() {
        // Observer pour le debugging CloudKit
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudKitEvent(_:)),
            name: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil
        )
    }
    
    @objc private func handleCloudKitEvent(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event else {
            return
        }
        
        if event.endDate == nil {
            print("☁️ CloudKit: Start event: \(event.type == .import ? "Import" : "Export")")
        } else {
            if let error = event.error {
                print("❌ CloudKit: Error event: \(event.type == .import ? "Import" : "Export") - \(error.localizedDescription)")
            } else {
                print("✅ CloudKit: Success event: \(event.type == .import ? "Import" : "Export")")
            }
        }
    }
    
    // MARK: - Core Data Stack (local avec App Group)
    // MARK: - Core Data Stack (local avec App Group & CloudKit)
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "Pinpin")
        
        // Configuration du store dans l'App Group
        guard let storeURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: groupID)?
            .appendingPathComponent("Pinpin.sqlite") else {
            fatalError("Impossible d'obtenir l'URL du container App Group")
        }
        
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        
        // Configuration CloudKit
        storeDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.misericode.Pinpin"
        )
        
        // Historique et notifications pour synchronisation cross-process
        storeDescription.setOption(true as NSNumber, 
                                 forKey: NSPersistentHistoryTrackingKey)
        storeDescription.setOption(true as NSNumber, 
                                 forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.persistentStoreDescriptions = [storeDescription]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Erreur Core Data: \(error)")
            }
        }
        
        // Configuration du contexte principal
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    lazy var context: NSManagedObjectContext = {
        return persistentContainer.viewContext
    }()
    
    // MARK: - Save Context
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Erreur Core Data: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // MARK: - Category Management
    func createDefaultCategoriesIfNeeded() {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        
        do {
            let count = try context.count(for: request)
            if count == 0 {
                createDefaultCategories()
            }
        } catch {
            print("Erreur lors de la vérification des catégories: \(error)")
        }
    }
    
    private func createDefaultCategories() {
        // Pas de catégories par défaut au premier lancement
        // L'utilisateur devra créer ses propres catégories
    }
    
    // MARK: - Category Queries
    func fetchCategories() -> [Category] {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.sortOrder, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Erreur lors de la récupération des catégories: \(error)")
            return []
        }
    }
    
    func fetchCategoryNames() -> [String] {
        return fetchCategories().compactMap { $0.name }
    }
    
    func addCategory(name: String, colorHex: String = "#007AFF", iconName: String = "folder") {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // Vérifier que le nom n'existe pas déjà
        let existingCategories = fetchCategories()
        if existingCategories.contains(where: { $0.name == trimmedName }) {
            return
        }
        
        let category = Category(context: context)
        category.id = UUID()
        category.name = trimmedName
        category.colorHex = colorHex
        category.iconName = iconName
        category.sortOrder = Int32(existingCategories.count)
        category.isDefault = existingCategories.isEmpty
        let now = Date()
        category.createdAt = now
        category.updatedAt = now
        
        save()
    }
    
    func getDefaultCategoryName() -> String {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "isDefault == YES")
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first?.name ?? "Général"
        } catch {
            return "Général"
        }
    }
    
    /// Compte le nombre d'items pour une catégorie donnée
    func countItems(for categoryName: String) -> Int {
        let request: NSFetchRequest<ContentItem> = ContentItem.fetchRequest()
        request.predicate = NSPredicate(format: "category.name == %@", categoryName)
        
        do {
            return try context.count(for: request)
        } catch {
            print("Erreur lors du comptage des items pour \(categoryName): \(error)")
            return 0
        }
    }
    
    /// Récupère la première image d'une catégorie pour l'aperçu
    func fetchFirstImageURL(for categoryName: String) -> String? {
        let request: NSFetchRequest<ContentItem> = ContentItem.fetchRequest()
        request.predicate = NSPredicate(format: "category.name == %@ AND thumbnailUrl != nil", categoryName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ContentItem.createdAt, ascending: false)]
        request.fetchLimit = 1
        
        do {
            let items = try context.fetch(request)
            return items.first?.thumbnailUrl
        } catch {
            return nil
        }
    }
}
