//
//  SharedModelContainer.swift
//  Pinpin
//
//  Configuration partagée du ModelContainer pour l'app principale et la Share Extension
//

import Foundation
import CoreData

public class SharedModelContainer {
    public static let shared = SharedModelContainer()
    
    private init() {}
    
    // MARK: - Shared Persistent Container
    public lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Pinpin")
        
        // Configuration pour App Group partagé
        if let storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.misericode.pinpin")?.appendingPathComponent("Pinpin.sqlite") {
            let storeDescription = NSPersistentStoreDescription(url: storeURL)
            storeDescription.shouldInferMappingModelAutomatically = true
            storeDescription.shouldMigrateStoreAutomatically = true
            container.persistentStoreDescriptions = [storeDescription]
        }
        
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Erreur Core Data: \(error)")
                return
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    public var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Save Context
    public func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Erreur Core Data: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // MARK: - Category Count (pour la Share Extension)
    public func getItemCount(for category: String) -> Int {
        let request: NSFetchRequest<ContentItem> = ContentItem.fetchRequest()
        request.predicate = NSPredicate(format: "category == %@", category)
        
        do {
            let count = try context.count(for: request)
            return count
        } catch {
            print("Erreur lors du comptage pour la catégorie \(category): \(error)")
            return 0
        }
    }
}
