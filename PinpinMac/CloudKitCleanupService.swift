//
//  CloudKitCleanupService.swift
//  Pinpin
//
//  Service pour nettoyer les métadonnées Core Data + CloudKit obsolètes
//

import Foundation
import CloudKit

@MainActor
final class CloudKitCleanupService {
    static let shared = CloudKitCleanupService()
    
    private let container: CKContainer
    private let database: CKDatabase
    
    private init() {
        container = CKContainer(identifier: AppConstants.cloudKitContainerID)
        database = container.privateCloudDatabase
    }
    
    /// Nettoie les anciennes métadonnées Core Data + CloudKit
    func cleanupCoreDataMetadata() async {
        print("[CloudKitCleanup] 🧹 Début du nettoyage des métadonnées Core Data...")
        
        // 1. Supprimer les anciennes zones Core Data
        await deleteOldCoreDataZones()
        
        // 2. Nettoyer les fichiers locaux
        cleanupLocalCoreDataFiles()
        
        print("[CloudKitCleanup] ✅ Nettoyage terminé")
    }
    
    /// Supprime les zones CloudKit créées par Core Data
    private func deleteOldCoreDataZones() async {
        let coreDataZoneName = "com.apple.coredata.cloudkit.zone"
        let zoneID = CKRecordZone.ID(zoneName: coreDataZoneName, ownerName: CKCurrentUserDefaultName)
        
        do {
            try await database.deleteRecordZone(withID: zoneID)
            print("[CloudKitCleanup] ✅ Zone Core Data supprimée: \(coreDataZoneName)")
        } catch let error as CKError {
            if error.code == .zoneNotFound {
                print("[CloudKitCleanup] ℹ️ Zone Core Data déjà supprimée")
            } else {
                print("[CloudKitCleanup] ⚠️ Erreur suppression zone: \(error.localizedDescription)")
            }
        } catch {
            print("[CloudKitCleanup] ⚠️ Erreur inattendue: \(error)")
        }
    }
    
    /// Nettoie les fichiers Core Data locaux dans l'App Group
    private func cleanupLocalCoreDataFiles() {
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.groupID) else {
            print("[CloudKitCleanup] ❌ App Group inaccessible")
            return
        }
        
        let fileManager = FileManager.default
        let coreDataFiles = [
            "Pinpin.sqlite",
            "Pinpin.sqlite-shm",
            "Pinpin.sqlite-wal",
            ".Pinpin_SUPPORT",
            ".Pinpin_SUPPORT/_EXTERNAL_DATA"
        ]
        
        for fileName in coreDataFiles {
            let fileURL = groupURL.appendingPathComponent(fileName)
            
            if fileManager.fileExists(atPath: fileURL.path) {
                do {
                    try fileManager.removeItem(at: fileURL)
                    print("[CloudKitCleanup] 🗑️ Supprimé: \(fileName)")
                } catch {
                    print("[CloudKitCleanup] ⚠️ Impossible de supprimer \(fileName): \(error)")
                }
            }
        }
    }
    
    /// Vérifie si des métadonnées Core Data existent encore
    func hasCoreDataMetadata() -> Bool {
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.groupID) else {
            return false
        }
        
        let coreDataFile = groupURL.appendingPathComponent("Pinpin.sqlite")
        return FileManager.default.fileExists(atPath: coreDataFile.path)
    }
}
