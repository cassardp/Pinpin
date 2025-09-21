//
//  CoreDataService.swift
//  PinpinShareExtension
//
//  Service Core Data simplifié pour la Share Extension
//

import Foundation
import CoreData

@MainActor
class CoreDataService: ObservableObject {
    static let shared = CoreDataService()
    
    // MARK: - Core Data Stack
    lazy var persistentContainer: NSPersistentContainer = {
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
                print("Erreur Core Data dans Share Extension: \(error)")
                return
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
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
                print("Erreur Core Data dans Share Extension: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
