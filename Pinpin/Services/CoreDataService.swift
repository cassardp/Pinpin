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
    private let cloudKitContainerID = "iCloud.com.misericode.pinpin"
    
    // MARK: - Core Data Stack (local avec App Group)
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Pinpin")
        
        // Configuration du store dans l'App Group
        guard let storeURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: groupID)?
            .appendingPathComponent("Pinpin.sqlite") else {
            fatalError("Impossible d'obtenir l'URL du container App Group")
        }
        
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        
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
}
