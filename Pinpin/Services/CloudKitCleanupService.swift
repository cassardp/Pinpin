//
//  CloudKitCleanupService.swift
//  Pinpin
//
//  Service pour nettoyer CloudKit et forcer une resynchronisation depuis les données locales
//

import Foundation
import CloudKit
import SwiftData

@MainActor
final class CloudKitCleanupService: ObservableObject {
    @Published var isCleaningUp = false
    @Published var cleanupProgress: String = ""
    @Published var cleanupError: String?
    
    private let container = CKContainer(identifier: AppConstants.cloudKitContainerID)
    private let privateDatabase: CKDatabase
    
    init() {
        self.privateDatabase = container.privateCloudDatabase
    }
    
    // MARK: - Main Cleanup Method
    
    /// Nettoie toutes les données CloudKit et force une resynchronisation depuis les données locales
    func cleanupCloudKitAndResync() async throws {
        isCleaningUp = true
        cleanupError = nil
        cleanupProgress = "Starting cleanup..."
        
        do {
            // Étape 1: Supprimer tous les enregistrements CloudKit
            cleanupProgress = "Deleting CloudKit records..."
            try await deleteAllCloudKitRecords()
            
            // Étape 2: Attendre un peu pour que CloudKit traite les suppressions
            cleanupProgress = "Waiting for CloudKit to process..."
            try await Task.sleep(for: .seconds(2))
            
            // Étape 3: Forcer une nouvelle synchronisation
            cleanupProgress = "Forcing resync from local data..."
            try await forceSyncFromLocal()
            
            cleanupProgress = "Cleanup completed successfully!"
            
            // Attendre 2 secondes avant de réinitialiser
            try await Task.sleep(for: .seconds(2))
            cleanupProgress = ""
            
        } catch {
            cleanupError = "Cleanup failed: \(error.localizedDescription)"
            cleanupProgress = ""
            throw error
        }
        
        isCleaningUp = false
    }
    
    // MARK: - Private Methods
    
    /// Supprime tous les enregistrements CloudKit en supprimant les zones personnalisées
    private func deleteAllCloudKitRecords() async throws {
        // Approche simplifiée : supprimer toutes les zones personnalisées
        // SwiftData crée des zones pour gérer la synchronisation
        let allZones = try await fetchAllRecordZones()
        
        print("[CloudKitCleanup] Found \(allZones.count) CloudKit zones:")
        for zone in allZones {
            print("[CloudKitCleanup]   - \(zone.zoneID.zoneName) (owner: \(zone.zoneID.ownerName))")
        }
        
        // Filtrer pour ne garder que les zones personnalisées (pas la zone par défaut)
        let customZones = allZones.filter { $0.zoneID.zoneName != CKRecordZone.ID.defaultZoneName }
        
        // Supprimer les zones personnalisées
        if !customZones.isEmpty {
            print("[CloudKitCleanup] Deleting \(customZones.count) custom zones...")
            try await deleteRecordZones(customZones.map { $0.zoneID })
            print("[CloudKitCleanup] ✅ Custom zones deleted")
        }
        
        // TOUJOURS nettoyer aussi la zone par défaut
        print("[CloudKitCleanup] Cleaning default zone...")
        try await deleteFromDefaultZone()
        print("[CloudKitCleanup] ✅ Default zone cleaned")
    }
    
    /// Récupère toutes les zones d'enregistrement
    private func fetchAllRecordZones() async throws -> [CKRecordZone] {
        return try await withCheckedThrowingContinuation { continuation in
            privateDatabase.fetchAllRecordZones { zones, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: zones ?? [])
                }
            }
        }
    }
    
    /// Supprime des zones d'enregistrement
    private func deleteRecordZones(_ zoneIDs: [CKRecordZone.ID]) async throws {
        let operation = CKModifyRecordZonesOperation(recordZonesToSave: nil, recordZoneIDsToDelete: zoneIDs)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.modifyRecordZonesResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            privateDatabase.add(operation)
        }
    }
    
    /// Méthode alternative : suppression depuis la zone par défaut
    private func deleteFromDefaultZone() async throws {
        // Utiliser fetchAllRecordZoneChanges pour récupérer les enregistrements
        let zoneID = CKRecordZone.default().zoneID
        
        var recordIDsToDelete: [CKRecord.ID] = []
        
        let configuration = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
        configuration.previousServerChangeToken = nil
        
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [zoneID], configurationsByRecordZoneID: [zoneID: configuration])
        
        operation.recordWasChangedBlock = { recordID, result in
            if case .success = result {
                recordIDsToDelete.append(recordID)
            }
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.fetchRecordZoneChangesResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            privateDatabase.add(operation)
        }
        
        if !recordIDsToDelete.isEmpty {
            print("[CloudKitCleanup] Found \(recordIDsToDelete.count) records to delete")
            try await deleteRecordsBatch(recordIDsToDelete)
        }
    }
    
    /// Supprime un lot d'enregistrements
    private func deleteRecordsBatch(_ recordIDs: [CKRecord.ID]) async throws {
        // Supprimer par lots de 400 (limite CloudKit)
        let batchSize = 400
        for batchStart in stride(from: 0, to: recordIDs.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, recordIDs.count)
            let batch = Array(recordIDs[batchStart..<batchEnd])
            
            let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: batch)
            operation.savePolicy = .changedKeys
            
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                operation.modifyRecordsResultBlock = { result in
                    switch result {
                    case .success:
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                
                privateDatabase.add(operation)
            }
            
            print("[CloudKitCleanup] Deleted batch \(batchStart/batchSize + 1) (\(batch.count) records)")
        }
    }
    
    /// Force une synchronisation depuis les données locales
    private func forceSyncFromLocal() async throws {
        // SwiftData avec CloudKit synchronise automatiquement
        // On force juste une sauvegarde du contexte pour déclencher la sync
        let dataService = DataService.shared
        dataService.save()
        
        // Attendre que la synchronisation démarre
        try await Task.sleep(for: .seconds(1))
        
        print("[CloudKitCleanup] ✅ Forced sync from local data")
    }
    
    // MARK: - Diagnostic Methods
    
    /// Affiche les statistiques de synchronisation pour diagnostiquer les décalages
    func diagnoseSync() async throws {
        print("\n[CloudKitCleanup] 🔍 Diagnostic de synchronisation")
        
        // Compter les items locaux
        let dataService = DataService.shared
        let context = dataService.context
        
        let itemsDescriptor = FetchDescriptor<ContentItem>()
        let localItems = try context.fetch(itemsDescriptor)
        
        let categoriesDescriptor = FetchDescriptor<Category>()
        let localCategories = try context.fetch(categoriesDescriptor)
        
        print("[CloudKitCleanup] 📱 Local data:")
        print("[CloudKitCleanup]   - ContentItems: \(localItems.count)")
        print("[CloudKitCleanup]   - Categories: \(localCategories.count)")
        
        // Vérifier les doublons d'ID
        let uniqueItemIds = Set(localItems.map { $0.id })
        if uniqueItemIds.count != localItems.count {
            let duplicateCount = localItems.count - uniqueItemIds.count
            print("[CloudKitCleanup] ⚠️ Found \(duplicateCount) duplicate item IDs!")
        } else {
            print("[CloudKitCleanup] ✅ No duplicate IDs")
        }
        
        // Afficher les catégories en détail
        print("[CloudKitCleanup] 📂 Categories list:")
        for (index, category) in localCategories.enumerated() {
            let itemCount = category.contentItems?.count ?? 0
            print("[CloudKitCleanup]   \(index + 1). '\(category.name)' - \(itemCount) items")
        }
        
        // Compter les catégories vides
        let emptyCategories = localCategories.filter { ($0.contentItems?.count ?? 0) == 0 }
        if !emptyCategories.isEmpty {
            print("[CloudKitCleanup] ⚠️ Empty categories found: \(emptyCategories.count)")
            for category in emptyCategories {
                print("[CloudKitCleanup]   - '\(category.name)'")
            }
        }
        
        // Compter les records CloudKit
        let allZones = try await fetchAllRecordZones()
        
        for zone in allZones {
            print("[CloudKitCleanup] ☁️ Zone: \(zone.zoneID.zoneName)")
            let count = try await countRecordsInZone(zone.zoneID)
            print("[CloudKitCleanup]   - Total records: \(count)")
        }
        
        print("[CloudKitCleanup] ✅ Diagnostic terminé\n")
    }
    
    /// Nettoie les catégories vides (sans items)
    func cleanupEmptyCategories() async throws {
        print("\n[CloudKitCleanup] 🧹 Nettoyage des catégories vides")
        
        let dataService = DataService.shared
        let context = dataService.context
        
        let categoriesDescriptor = FetchDescriptor<Category>()
        let allCategories = try context.fetch(categoriesDescriptor)
        
        let emptyCategories = allCategories.filter { ($0.contentItems?.count ?? 0) == 0 }
        
        if emptyCategories.isEmpty {
            print("[CloudKitCleanup] ✅ Aucune catégorie vide trouvée")
            return
        }
        
        print("[CloudKitCleanup] Found \(emptyCategories.count) empty categories:")
        for category in emptyCategories {
            print("[CloudKitCleanup]   - Deleting '\(category.name)'")
            context.delete(category)
        }
        
        try context.save()
        
        print("[CloudKitCleanup] ✅ \(emptyCategories.count) catégories vides supprimées\n")
    }
    
    /// Supprime les items en double (même ID)
    func removeDuplicateItems() async throws {
        print("\n[CloudKitCleanup] 🔍 Recherche des items en double")
        
        let dataService = DataService.shared
        let context = dataService.context
        
        let itemsDescriptor = FetchDescriptor<ContentItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)] // Garder le plus ancien
        )
        let allItems = try context.fetch(itemsDescriptor)
        
        // Grouper par ID
        var itemsByID: [UUID: [ContentItem]] = [:]
        for item in allItems {
            itemsByID[item.id, default: []].append(item)
        }
        
        var deletedCount = 0
        
        for (id, items) in itemsByID where items.count > 1 {
            print("[CloudKitCleanup] Found \(items.count) items with ID \(id):")
            
            // Garder le premier (plus ancien)
            let keeper = items[0]
            let duplicates = Array(items.dropFirst())
            
            print("[CloudKitCleanup]   ✅ Keeping: '\(keeper.title)' (created: \(keeper.createdAt))")
            
            // Supprimer les doublons
            for duplicate in duplicates {
                print("[CloudKitCleanup]   ❌ Deleting: '\(duplicate.title)' (created: \(duplicate.createdAt))")
                context.delete(duplicate)
                deletedCount += 1
            }
        }
        
        if deletedCount > 0 {
            try context.save()
            print("[CloudKitCleanup] ✅ Supprimé \(deletedCount) items en double\n")
        } else {
            print("[CloudKitCleanup] ✅ Aucun item en double trouvé\n")
        }
    }
    
    /// Fusionne les catégories en double (même nom, casse différente ou doublons exacts)
    func mergeDuplicateCategories() async throws {
        print("\n[CloudKitCleanup] 🔀 Fusion des catégories en double")
        
        let dataService = DataService.shared
        let context = dataService.context
        
        let categoriesDescriptor = FetchDescriptor<Category>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)] // Garder la plus ancienne
        )
        let allCategories = try context.fetch(categoriesDescriptor)
        
        // Grouper par nom (insensible à la casse)
        var categoryGroups: [String: [Category]] = [:]
        for category in allCategories {
            let normalizedName = category.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            categoryGroups[normalizedName, default: []].append(category)
        }
        
        var mergedCount = 0
        var deletedCount = 0
        
        for (normalizedName, categories) in categoryGroups where categories.count > 1 {
            print("[CloudKitCleanup] Found \(categories.count) duplicates for '\(normalizedName)':")
            
            // Garder la première (plus ancienne)
            let keeper = categories[0]
            let duplicates = Array(categories.dropFirst())
            
            print("[CloudKitCleanup]   ✅ Keeping: '\(keeper.name)' (\(keeper.contentItems?.count ?? 0) items)")
            
            // Fusionner les items des doublons vers la catégorie à garder
            for duplicate in duplicates {
                let itemCount = duplicate.contentItems?.count ?? 0
                print("[CloudKitCleanup]   ❌ Merging: '\(duplicate.name)' (\(itemCount) items)")
                
                if let items = duplicate.contentItems {
                    for item in items {
                        item.category = keeper
                    }
                    mergedCount += itemCount
                }
                
                context.delete(duplicate)
                deletedCount += 1
            }
        }
        
        if deletedCount > 0 {
            try context.save()
            print("[CloudKitCleanup] ✅ Fusionné \(mergedCount) items et supprimé \(deletedCount) doublons\n")
        } else {
            print("[CloudKitCleanup] ✅ Aucun doublon trouvé\n")
        }
    }
    
    /// Compte les enregistrements dans une zone avec détails par type
    private func countRecordsInZone(_ zoneID: CKRecordZone.ID) async throws -> Int {
        var recordCount = 0
        var recordTypes: [String: Int] = [:]
        
        let configuration = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
        configuration.previousServerChangeToken = nil
        
        let operation = CKFetchRecordZoneChangesOperation(
            recordZoneIDs: [zoneID],
            configurationsByRecordZoneID: [zoneID: configuration]
        )
        
        operation.recordWasChangedBlock = { _, result in
            recordCount += 1
            if case .success(let record) = result {
                let typeName = record.recordType
                recordTypes[typeName, default: 0] += 1
            }
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.fetchRecordZoneChangesResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            privateDatabase.add(operation)
        }
        
        // Afficher les détails par type
        if !recordTypes.isEmpty {
            print("[CloudKitCleanup]   Record types:")
            for (type, count) in recordTypes.sorted(by: { $0.key < $1.key }) {
                print("[CloudKitCleanup]     - \(type): \(count)")
            }
        }
        
        return recordCount
    }
}
