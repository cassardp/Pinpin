//
//  DataService.swift
//  PinpinShareExtension
//
//  Service SwiftData pour la Share Extension
//

import Foundation
import SwiftData

@MainActor
final class DataService {
    static let shared = DataService()
    
    private let groupID = "group.com.misericode.pinpin"
    
    // MARK: - SwiftData Container
    lazy var container: ModelContainer = {
        let schema = Schema([ContentItem.self, Category.self])
        
        // Configuration pour App Group sans CloudKit
        let configuration = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(groupID),
            cloudKitDatabase: .none
        )
        
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            return container
        } catch {
            print("Erreur lors de la création du ModelContainer dans l'extension: \(error)")
            // Fallback vers un container en mémoire pour éviter le crash
            do {
                let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                return try ModelContainer(for: schema, configurations: [fallbackConfig])
            } catch {
                fatalError("Impossible de créer même un ModelContainer en mémoire: \(error)")
            }
        }
    }()
    
    var context: ModelContext {
        return container.mainContext
    }
    
    private init() {}
    
    // MARK: - Category Management
    func fetchCategoryNames() -> [String] {
        let descriptor = FetchDescriptor<Category>(
            sortBy: [SortDescriptor(\.sortOrder, order: .forward)]
        )
        
        do {
            let categories = try context.fetch(descriptor)
            return categories.map { $0.name }
        } catch {
            print("Erreur lors de la récupération des catégories dans l'extension: \(error)")
            return ["Général"] // Fallback
        }
    }
    
    /// Trouve ou crée une catégorie par nom
    func findOrCreateCategory(name: String) -> Category {
        // Chercher la catégorie existante
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { $0.name == name }
        )
        
        do {
            let categories = try context.fetch(descriptor)
            if let existingCategory = categories.first {
                return existingCategory
            }
        } catch {
            print("Erreur lors de la recherche de catégorie dans l'extension: \(error)")
        }
        
        // Créer une nouvelle catégorie si elle n'existe pas
        let existingCategories = fetchCategories()
        let newCategory = Category(
            name: name,
            sortOrder: Int32(existingCategories.count),
            isDefault: existingCategories.isEmpty
        )
        
        context.insert(newCategory)
        save()
        return newCategory
    }
    
    private func fetchCategories() -> [Category] {
        let descriptor = FetchDescriptor<Category>(
            sortBy: [SortDescriptor(\.sortOrder, order: .forward)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Erreur lors de la récupération des catégories: \(error)")
            return []
        }
    }
    
    func addCategory(name: String, colorHex: String = "#007AFF", iconName: String = "folder") {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // Vérifier que le nom n'existe pas déjà
        let existingCategories = fetchCategories()
        if existingCategories.contains(where: { $0.name == trimmedName }) {
            return
        }
        
        let category = Category(
            name: trimmedName,
            colorHex: colorHex,
            iconName: iconName,
            sortOrder: Int32(existingCategories.count),
            isDefault: existingCategories.isEmpty
        )
        
        context.insert(category)
        save()
    }
    
    func countItems(for categoryName: String) -> Int {
        let descriptor = FetchDescriptor<ContentItem>(
            predicate: #Predicate { $0.category?.name == categoryName }
        )
        
        do {
            let items = try context.fetch(descriptor)
            return items.count
        } catch {
            print("Erreur lors du comptage des items: \(error)")
            return 0
        }
    }
    
    func fetchFirstImageURL(for categoryName: String) -> String? {
        var descriptor = FetchDescriptor<ContentItem>(
            predicate: #Predicate { item in
                item.category?.name == categoryName && item.thumbnailUrl != nil
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        
        do {
            let items = try context.fetch(descriptor)
            return items.first?.thumbnailUrl
        } catch {
            print("Erreur lors de la récupération de la première image: \(error)")
            return nil
        }
    }
    
    // MARK: - Save Context
    func save() {
        do {
            try context.save()
        } catch {
            print("Erreur lors de la sauvegarde dans l'extension: \(error)")
        }
    }
}
