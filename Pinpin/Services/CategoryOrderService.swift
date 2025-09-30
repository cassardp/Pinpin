//
//  CategoryOrderService.swift
//  Pinpin
//
//  Service pour gérer l'ordre personnalisé des catégories dans le FilterMenu
//

import Foundation
import Combine

class CategoryOrderService: ObservableObject {
    static let shared = CategoryOrderService()
    
    private let userDefaults: UserDefaults
    private let categoryOrderKey = AppConstants.categoryOrderKey
    
    @Published var categoryOrder: [String] = []
    
    private init() {
        userDefaults = .standard
        loadCategoryOrder()
    }

    /// Charge l'ordre des catégories depuis UserDefaults avec nettoyage anti-doublons
    private func loadCategoryOrder() {
        let rawOrder = userDefaults.stringArray(forKey: categoryOrderKey) ?? []
        
        // Nettoyer immédiatement les doublons au chargement
        let cleanOrder = Array(NSOrderedSet(array: rawOrder)) as! [String]
        
        // Si des doublons ont été trouvés, sauvegarder la version nettoyée
        if cleanOrder.count != rawOrder.count {
            print("🧹 Nettoyage des doublons dans CategoryOrderService: \(rawOrder.count) → \(cleanOrder.count)")
            categoryOrder = cleanOrder
            saveCategoryOrder()
        } else {
            categoryOrder = cleanOrder
        }
    }
    
    /// Sauvegarde l'ordre des catégories dans UserDefaults
    private func saveCategoryOrder() {
        userDefaults.set(categoryOrder, forKey: categoryOrderKey)
    }
    
    /// Applique l'ordre personnalisé aux catégories disponibles avec blindage anti-doublons
    /// Les nouvelles catégories sont ajoutées à la fin
    func orderedCategories(from availableCategories: [String]) -> [String] {
        // 1. Nettoyer les catégories disponibles des doublons potentiels
        let cleanAvailableCategories = Array(Set(availableCategories))
        
        // 2. Nettoyer l'ordre sauvegardé des doublons
        let cleanSavedOrder = Array(NSOrderedSet(array: categoryOrder)) as! [String]
        
        // 3. Construire la liste finale sans doublons
        var orderedList: [String] = []
        var processedCategories = Set<String>()
        
        // Ajouter les catégories dans l'ordre sauvegardé si elles existent encore
        for category in cleanSavedOrder {
            if cleanAvailableCategories.contains(category) && !processedCategories.contains(category) {
                orderedList.append(category)
                processedCategories.insert(category)
            }
        }
        
        // Ajouter les nouvelles catégories à la fin (sans doublons)
        for category in cleanAvailableCategories {
            if !processedCategories.contains(category) {
                orderedList.append(category)
                processedCategories.insert(category)
            }
        }
        
        // 4. Vérification finale : s'assurer qu'il n'y a aucun doublon
        let finalOrderedList = Array(NSOrderedSet(array: orderedList)) as! [String]
        
        // Mettre à jour l'ordre sauvegardé si nécessaire (avec nettoyage)
        if finalOrderedList != cleanSavedOrder {
            DispatchQueue.main.async {
                self.categoryOrder = finalOrderedList
                self.saveCategoryOrder()
            }
        }
        
        return finalOrderedList
    }
    
    /// Réorganise les catégories (utilisé par le glisser-déposer) avec blindage anti-doublons
    func reorderCategories(from source: IndexSet, to destination: Int) {
        // Nettoyer avant la réorganisation
        let cleanOrder = Array(NSOrderedSet(array: categoryOrder)) as! [String]
        categoryOrder = cleanOrder
        
        // Effectuer la réorganisation
        categoryOrder.move(fromOffsets: source, toOffset: destination)
        
        // Nettoyer après la réorganisation (sécurité supplémentaire)
        let finalOrder = Array(NSOrderedSet(array: categoryOrder)) as! [String]
        categoryOrder = finalOrder
        
        saveCategoryOrder()
    }
    
    /// Met à jour l'ordre complet des catégories avec nettoyage anti-doublons
    func updateCategoryOrder(_ newOrder: [String]) {
        // Nettoyer les doublons avant sauvegarde
        let cleanOrder = Array(NSOrderedSet(array: newOrder)) as! [String]
        categoryOrder = cleanOrder
        saveCategoryOrder()
    }

    /// Renomme une catégorie dans l'ordre stocké
    func renameCategory(oldName: String, newName: String) {
        guard let index = categoryOrder.firstIndex(of: oldName) else { return }
        categoryOrder[index] = newName
        saveCategoryOrder()
    }

    /// Supprime une catégorie de l'ordre stocké
    func removeCategory(named name: String) {
        guard let index = categoryOrder.firstIndex(of: name) else { return }
        categoryOrder.remove(at: index)
        saveCategoryOrder()
    }
    
    // MARK: - Diagnostic et nettoyage
    
    /// Diagnostique et nettoie les doublons dans UserDefaults
    func cleanupDuplicates() {
        let originalCount = categoryOrder.count
        let cleanOrder = Array(NSOrderedSet(array: categoryOrder)) as! [String]
        
        if cleanOrder.count != originalCount {
            print("🧹 Nettoyage forcé des doublons: \(originalCount) → \(cleanOrder.count)")
            categoryOrder = cleanOrder
            saveCategoryOrder()
        }
    }
    
    /// Vérifie s'il y a des doublons dans l'ordre actuel
    func hasDuplicates() -> Bool {
        return categoryOrder.count != Set(categoryOrder).count
    }
    
    /// Retourne les catégories dupliquées
    func getDuplicates() -> [String] {
        var seen = Set<String>()
        var duplicates = Set<String>()
        
        for category in categoryOrder {
            if !seen.insert(category).inserted {
                duplicates.insert(category)
            }
        }
        
        return Array(duplicates)
    }
}
