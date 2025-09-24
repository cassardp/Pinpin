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
    private let categoryOrderKey = "categoryOrder"
    
    @Published var categoryOrder: [String] = []
    
    private init() {
        userDefaults = .standard
        loadCategoryOrder()
    }

    /// Charge l'ordre des catégories depuis UserDefaults
    private func loadCategoryOrder() {
        categoryOrder = userDefaults.stringArray(forKey: categoryOrderKey) ?? []
    }
    
    /// Sauvegarde l'ordre des catégories dans UserDefaults
    private func saveCategoryOrder() {
        userDefaults.set(categoryOrder, forKey: categoryOrderKey)
    }
    
    /// Applique l'ordre personnalisé aux catégories disponibles
    /// Les nouvelles catégories sont ajoutées à la fin
    func orderedCategories(from availableCategories: [String]) -> [String] {
        var orderedList: [String] = []
        
        // Ajouter les catégories dans l'ordre sauvegardé si elles existent encore
        for category in categoryOrder {
            if availableCategories.contains(category) {
                orderedList.append(category)
            }
        }
        
        // Ajouter les nouvelles catégories à la fin
        for category in availableCategories {
            if !orderedList.contains(category) {
                orderedList.append(category)
            }
        }
        
        // Mettre à jour l'ordre sauvegardé si de nouvelles catégories ont été ajoutées
        if orderedList != categoryOrder {
            DispatchQueue.main.async {
                self.categoryOrder = orderedList
                self.saveCategoryOrder()
            }
        }
        
        return orderedList
    }
    
    /// Réorganise les catégories (utilisé par le glisser-déposer)
    func reorderCategories(from source: IndexSet, to destination: Int) {
        categoryOrder.move(fromOffsets: source, toOffset: destination)
        saveCategoryOrder()
    }
    
    /// Met à jour l'ordre complet des catégories
    func updateCategoryOrder(_ newOrder: [String]) {
        categoryOrder = newOrder
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
}
