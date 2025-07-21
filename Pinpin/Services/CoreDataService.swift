//
//  CoreDataService.swift
//  Neeed2
//
//  Service Core Data simple (sans CloudKit pour commencer)
//

import Foundation
import CoreData

@MainActor
class CoreDataService: ObservableObject {
    static let shared = CoreDataService()
    
    // MARK: - Core Data Stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Pinpin")
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Erreur Core Data: \(error)")
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
                fatalError("Erreur Core Data: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
