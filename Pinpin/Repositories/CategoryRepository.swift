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
    
    func fetchNames() throws -> [String] {
        let categories = try fetchAll()
        var seen = Set<UUID>()
        return categories.compactMap { category in
            guard seen.insert(category.id).inserted else { return nil }
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
        
        // Vérifier que le nom n'existe pas déjà
        if try exists(name: trimmedName) {
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
        if let existingCategory = try fetchByName(name) {
            return existingCategory
        }
        
        // Créer une nouvelle catégorie
        let existingCategories = try fetchAll()
        let newCategory = Category(
            name: name,
            sortOrder: Int32(existingCategories.count),
            isDefault: existingCategories.isEmpty
        )
        
        insert(newCategory)
        return newCategory
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
