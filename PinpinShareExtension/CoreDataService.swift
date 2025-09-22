//
//  CoreDataService.swift
//  PinpinShareExtension
//
//  Service Core Data pour la Share Extension (lecture seule)
//

import Foundation
import CoreData

class CoreDataService {
    static let shared = CoreDataService()
    
    private let groupID = "group.com.misericode.pinpin"
    
    // MARK: - Core Data Stack (lecture/écriture partagé)
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Pinpin")
        
        // Utiliser le même store que l'app principale
        guard let storeURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: groupID)?
            .appendingPathComponent("Pinpin.sqlite") else {
            fatalError("Impossible d'obtenir l'URL du container App Group")
        }
        
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        
        // Configuration pour synchronisation cross-process
        storeDescription.setOption(true as NSNumber, 
                                 forKey: NSPersistentHistoryTrackingKey)
        storeDescription.setOption(true as NSNumber, 
                                 forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.persistentStoreDescriptions = [storeDescription]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Erreur chargement store extension: \(error)")
                // Ne pas faire crash l'extension, juste logger
            }
        }
        
        // Configuration du contexte
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
                print("Erreur sauvegarde extension: \(error)")
            }
        }
    }
    
    // MARK: - Category Management
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
    
    func fetchDefaultCategory() -> Category? {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "isDefault == YES")
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Erreur lors de la récupération de la catégorie par défaut: \(error)")
            return nil
        }
    }
    
    /// Récupère seulement les noms des catégories
    func fetchCategoryNames() -> [String] {
        return fetchCategories().compactMap { $0.name }
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
    
    /// Ajoute une nouvelle catégorie depuis l'extension
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
        category.isDefault = existingCategories.isEmpty // Premier = défaut
        let now = Date()
        category.createdAt = now
        category.updatedAt = now
        
        save()
    }
}
