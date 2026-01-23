//
//  DatabaseMaintenanceService.swift
//  Pinpin
//
//  Service pour la maintenance de la base de données au démarrage
//  Dédoublonne les catégories et autres tâches de nettoyage
//

import Foundation
import SwiftData

/// Service de maintenance de la base de données
final class DatabaseMaintenanceService {
    
    static let shared = DatabaseMaintenanceService()
    
    private init() {}
    
    /// Effectue toutes les tâches de maintenance au démarrage
    /// - Parameter context: Le ModelContext à utiliser
    @MainActor
    func performStartupMaintenance(context: ModelContext) {
        deduplicateCategories(context: context)
    }
    
    /// Dédoublonne les catégories en fusionnant celles qui ont le même nom
    /// Les items des catégories en double sont déplacés vers la catégorie principale (la plus ancienne)
    /// - Parameter context: Le ModelContext à utiliser
    @MainActor
    func deduplicateCategories(context: ModelContext) {
        do {
            // Récupérer toutes les catégories
            let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.createdAt, order: .forward)])
            let allCategories = try context.fetch(descriptor)
            
            // Grouper par nom (case insensitive)
            var categoriesByName: [String: [Category]] = [:]
            for category in allCategories {
                let normalizedName = category.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                categoriesByName[normalizedName, default: []].append(category)
            }
            
            var deletedCount = 0
            var movedItemsCount = 0
            
            // Pour chaque groupe de catégories avec le même nom
            for (name, duplicates) in categoriesByName where duplicates.count > 1 {
                print("🔄 [Maintenance] Catégorie '\(name)' a \(duplicates.count) doublons")
                
                // Garder la première (la plus ancienne selon createdAt)
                let primaryCategory = duplicates[0]
                let duplicatesToDelete = Array(duplicates.dropFirst())
                
                // Déplacer tous les items des doublons vers la catégorie principale
                for duplicateCategory in duplicatesToDelete {
                    if let items = duplicateCategory.contentItems, !items.isEmpty {
                        for item in items {
                            item.category = primaryCategory
                            movedItemsCount += 1
                        }
                    }
                    // Supprimer le doublon
                    context.delete(duplicateCategory)
                    deletedCount += 1
                }
            }
            
            if deletedCount > 0 {
                try context.save()
                print("✅ [Maintenance] \(deletedCount) catégorie(s) doublon(s) supprimée(s), \(movedItemsCount) item(s) déplacé(s)")
            } else {
                print("✅ [Maintenance] Aucun doublon de catégorie détecté")
            }
            
        } catch {
            print("❌ [Maintenance] Erreur lors du dédoublonnage: \(error)")
        }
    }
}
