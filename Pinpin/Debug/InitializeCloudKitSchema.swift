//
//  InitializeCloudKitSchema.swift
//  Pinpin
//
//  Script pour initialiser le schéma CloudKit avec les bonnes REFERENCE
//  À exécuter UNE SEULE FOIS en Development après reset du schéma
//

import Foundation
import SwiftData
import CoreData

#if DEBUG
/// Initialise le schéma CloudKit avec les relations correctes (REFERENCE)
func initializeCloudKitSchema() {
    print("🔧 Initialisation du schéma CloudKit...")
    
    let config = ModelConfiguration()
    
    do {
        try autoreleasepool {
            let desc = NSPersistentStoreDescription(url: config.url)
            
            // Configuration CloudKit
            let options = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.misericode.Pinpin"
            )
            desc.cloudKitContainerOptions = options
            desc.shouldAddStoreAsynchronously = false
            
            // Conversion SwiftData → Core Data
            if let mom = NSManagedObjectModel.makeManagedObjectModel(
                for: [Category.self, ContentItem.self, UserPreferencesModel.self]
            ) {
                let container = NSPersistentCloudKitContainer(
                    name: "Pinpin",
                    managedObjectModel: mom
                )
                container.persistentStoreDescriptions = [desc]
                
                // Chargement du store
                container.loadPersistentStores { _, error in
                    if let error {
                        print("❌ Erreur de chargement: \(error.localizedDescription)")
                        return
                    }
                }
                
                // 🎯 INITIALISATION DU SCHÉMA CLOUDKIT
                print("📤 Création du schéma CloudKit...")
                try container.initializeCloudKitSchema()
                print("✅ Schéma CloudKit initialisé avec succès!")
                print("   → CD_category est maintenant de type REFERENCE")
                print("   → Vérifie dans CloudKit Dashboard")
                
                // Nettoyage
                if let store = container.persistentStoreCoordinator.persistentStores.first {
                    try container.persistentStoreCoordinator.remove(store)
                }
            } else {
                print("❌ Impossible de créer le NSManagedObjectModel")
            }
        }
    } catch {
        print("❌ Erreur: \(error.localizedDescription)")
    }
}
#endif
