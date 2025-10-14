//
//  CategoryRepository.swift
//  Pinpin
//
//  Repository pour la gestion des catégories
//

import Foundation
import SwiftData

@MainActor
final class CategoryRepository {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    // MARK: - CRUD Operations
    
    func insert(_ category: Category) {
        context.insert(category)
    }
    
    func delete(_ category: Category) {
        context.delete(category)
    }
    
    func update(_ category: Category) {
        category.updatedAt = Date()
    }

    func rename(_ category: Category, newName: String) throws {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        // Vérifier que le nouveau nom n'existe pas déjà (exact, sauf si c'est la même catégorie)
        if let existing = try fetchByName(trimmedName), existing.id != category.id {
            return
        }
        
        // Vérifier aussi insensible à la casse
        if let existing = try fetchByNameCaseInsensitive(trimmedName), existing.id != category.id {
            return
        }

        category.name = trimmedName
        update(category)
    }

    func updateSortOrder(categories: [(category: Category, order: Int32)]) {
        for (category, order) in categories {
            category.sortOrder = order
        }
    }

    // MARK: - Fetch Operations
    
    func fetchAll() throws -> [Category] {
        let descriptor = FetchDescriptor<Category>(
            sortBy: [SortDescriptor(\.sortOrder, order: .forward)]
        )
        return try context.fetch(descriptor)
    }
    
    func fetchByName(_ name: String) throws -> Category? {
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { $0.name == name }
        )
        return try context.fetch(descriptor).first
    }
    
    /// Recherche une catégorie par nom (insensible à la casse)
    func fetchByNameCaseInsensitive(_ name: String) throws -> Category? {
        let normalizedName = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let allCategories = try fetchAll()
        return allCategories.first { 
            $0.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == normalizedName 
        }
    }

    func fetchById(_ id: UUID) throws -> Category? {
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }
    
    func fetchNames() throws -> [String] {
        let categories = try fetchAll()
        var seen = Set<String>()
        return categories.compactMap { category in
            guard seen.insert(category.name).inserted else { return nil }
            return category.name
        }
    }
    
    func exists(name: String) throws -> Bool {
        return try fetchByName(name) != nil
    }
    
    // MARK: - Category Management
    
    func create(name: String, colorHex: String = "#007AFF", iconName: String = "folder") throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // Vérifier que le nom n'existe pas déjà (exact)
        if try exists(name: trimmedName) {
            return
        }
        
        // Vérifier aussi insensible à la casse
        if try fetchByNameCaseInsensitive(trimmedName) != nil {
            return
        }
        
        let existingCategories = try fetchAll()
        let category = Category(
            name: trimmedName,
            colorHex: colorHex,
            iconName: iconName,
            sortOrder: Int32(existingCategories.count),
            isDefault: existingCategories.isEmpty
        )
        
        insert(category)
    }
    
    func getDefaultCategoryName() throws -> String {
        let categories = try fetchAll()
        return categories.first(where: { $0.isDefault })?.name ?? AppConstants.defaultCategoryName
    }
    
    func findOrCreate(name: String) throws -> Category {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            // Fallback sur une catégorie par défaut si le nom est vide
            return try findOrCreateMiscCategory()
        }
        
        // Chercher d'abord avec la casse exacte
        if let existingCategory = try fetchByName(trimmedName) {
            return existingCategory
        }
        
        // Chercher ensuite insensible à la casse pour éviter les doublons
        if let existingCategory = try fetchByNameCaseInsensitive(trimmedName) {
            return existingCategory
        }

        // Créer une nouvelle catégorie
        let existingCategories = try fetchAll()
        let newCategory = Category(
            name: trimmedName,
            sortOrder: Int32(existingCategories.count),
            isDefault: existingCategories.isEmpty
        )

        insert(newCategory)
        return newCategory
    }

    func upsert(id: UUID, name: String, colorHex: String, iconName: String, sortOrder: Int32, isDefault: Bool, createdAt: Date, updatedAt: Date) throws -> Category {
        // Chercher d'abord par ID
        if let existing = try fetchById(id) {
            // Mettre à jour les propriétés
            existing.name = name
            existing.colorHex = colorHex
            existing.iconName = iconName
            existing.sortOrder = sortOrder
            existing.isDefault = isDefault
            existing.createdAt = createdAt
            existing.updatedAt = updatedAt
            return existing
        }
        
        // Ensuite chercher par nom
        if let existing = try fetchByName(name) {
            // Mettre à jour avec le nouvel ID
            existing.id = id
            existing.colorHex = colorHex
            existing.iconName = iconName
            existing.sortOrder = sortOrder
            existing.isDefault = isDefault
            existing.createdAt = createdAt
            existing.updatedAt = updatedAt
            return existing
        }

        // Créer une nouvelle catégorie
        let category = Category()
        category.id = id
        category.name = name
        category.colorHex = colorHex
        category.iconName = iconName
        category.sortOrder = sortOrder
        category.isDefault = isDefault
        category.createdAt = createdAt
        category.updatedAt = updatedAt

        insert(category)
        return category
    }
    
    // MARK: - Misc Category Management
    
    func findOrCreateMiscCategory() throws -> Category {
        // Chercher si l'utilisateur a créé une catégorie "Misc" manuellement
        for name in AppConstants.miscCategoryNames {
            if let existingCategory = try fetchByName(name) {
                return existingCategory
            }
        }
        
        // Créer une nouvelle catégorie "Misc"
        let existingCategories = try fetchAll()
        let miscCategory = Category(
            name: "Misc",
            colorHex: "#6B7280", // Gris
            iconName: "folder",
            sortOrder: Int32(existingCategories.count),
            isDefault: existingCategories.isEmpty
        )
        
        insert(miscCategory)
        return miscCategory
    }
    
    func cleanupEmptyMiscCategories() throws {
        let miscCategories = uniqueCategories(
            AppConstants.miscCategoryNames.compactMap { try? fetchByName($0) }
        )
        
        guard !miscCategories.isEmpty else { return }
        
        var didDelete = false
        
        for miscCategory in miscCategories where (miscCategory.contentItems ?? []).isEmpty {
            delete(miscCategory)
            didDelete = true
        }
        
        if didDelete {
            print("[CategoryRepository] Catégories Misc vides supprimées")
        }
    }
    
    // MARK: - Helper Methods
    
    private func uniqueCategories(_ categories: [Category]) -> [Category] {
        var seen = Set<UUID>()
        return categories.filter { seen.insert($0.id).inserted }
    }
}
