//
//  CategoryService.swift
//  Pinpin
//
//  Service pour gérer les catégories personnalisables
//

import Foundation
import SwiftUI

class CategoryService: ObservableObject {
    static let shared = CategoryService()
    
    @Published var categories: [String] = []
    
    private let userDefaults = UserDefaults(suiteName: "group.com.misericode.pinpin") ?? UserDefaults.standard
    private let categoriesKey = "user_categories"
    
    // Plus de catégories par défaut - liste vide au premier lancement
    
    private init() {
        loadCategories()
    }
    
    // MARK: - Public Methods
    
    /// Charge les catégories depuis UserDefaults
    func loadCategories() {
        if let savedCategories = userDefaults.array(forKey: categoriesKey) as? [String] {
            categories = savedCategories
        } else {
            // Premier lancement - liste vide
            categories = []
        }
    }
    
    /// Sauvegarde les catégories dans UserDefaults
    private func saveCategories() {
        userDefaults.set(categories, forKey: categoriesKey)
        userDefaults.synchronize() // Force la synchronisation pour les UserDefaults partagés
    }
    
    /// Ajoute une nouvelle catégorie
    func addCategory(_ name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty && !categories.contains(trimmedName) else { return }
        
        categories.append(trimmedName)
        saveCategories()
    }
    
    /// Supprime une catégorie
    func removeCategory(_ name: String) {
        categories.removeAll { $0 == name }
        saveCategories()
    }
    
    /// Renomme une catégorie
    func renameCategory(from oldName: String, to newName: String) {
        let trimmedNewName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNewName.isEmpty && !categories.contains(trimmedNewName) else { return }
        
        if let index = categories.firstIndex(of: oldName) {
            categories[index] = trimmedNewName
            saveCategories()
        }
    }
    
    /// Réorganise les catégories
    func reorderCategories(_ newOrder: [String]) {
        categories = newOrder
        saveCategories()
    }
    
    /// Vérifie si une catégorie existe
    func categoryExists(_ name: String) -> Bool {
        return categories.contains(name)
    }
    
    /// Retourne la première catégorie (par défaut)
    var defaultCategory: String {
        return categories.first ?? "General"
    }
}
