//
//  ShareExtensionDataService.swift
//  PinpinShareExtension
//
//  Service SwiftData simplifié pour la Share Extension - utilise les repositories
//

import Foundation
import SwiftData

@MainActor
final class ShareExtensionDataService {
    static let shared = ShareExtensionDataService()

    // MARK: - SwiftData Container
    lazy var container: ModelContainer = {
        prepareSharedContainerIfNeeded()
        let schema = Schema([ContentItem.self, Category.self])

        // Configuration pour App Group AVEC CloudKit (même config que l'app principale)
        let configuration = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(AppConstants.groupID),
            cloudKitDatabase: .automatic
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

    // Repositories
    private lazy var categoryRepo = CategoryRepository(context: context)
    private lazy var contentRepo = ContentItemRepository(context: context)

    private init() {}

    // MARK: - Category Management via Repository

    func fetchCategoryNames() -> [String] {
        do {
            return try categoryRepo.fetchNames()
        } catch {
            print("Erreur lors de la récupération des catégories dans l'extension: \(error)")
            return ["Général"] // Fallback
        }
    }

    func countItems(for categoryName: String) -> Int {
        do {
            return try contentRepo.count(for: categoryName)
        } catch {
            print("Erreur lors du comptage des items: \(error)")
            return 0
        }
    }

    func fetchFirstImageData(for categoryName: String) -> Data? {
        do {
            return try contentRepo.fetchFirstImageData(for: categoryName)
        } catch {
            print("Erreur lors de la récupération de la première image: \(error)")
            return nil
        }
    }

    func addCategory(name: String, colorHex: String = "#007AFF", iconName: String = "folder") {
        do {
            try categoryRepo.create(name: name, colorHex: colorHex, iconName: iconName)
            save()
        } catch {
            print("[ShareExtension] Erreur lors de la création de catégorie: \(error)")
        }
    }

    // MARK: - Save Context
    func save() {
        do {
            try context.save()
            print("[ShareExtension][DataService] ✅ Sauvegarde réussie!")
        } catch {
            print("[ShareExtension][DataService] ❌ Erreur sauvegarde: \(error)")
        }
    }

    private func prepareSharedContainerIfNeeded() {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.groupID) else {
            print("[ShareExtension][DataService] ❌ IMPOSSIBLE d'accéder au container partagé")
            return
        }
        print("[ShareExtension][DataService] ✅ Container URL: \(containerURL.path)")

        let libraryURL = containerURL.appendingPathComponent("Library", isDirectory: true)
        let supportURL = libraryURL.appendingPathComponent("Application Support", isDirectory: true)
        print("[ShareExtension][DataService] 📁 Support URL: \(supportURL.path)")

        do {
            try FileManager.default.createDirectory(at: supportURL, withIntermediateDirectories: true)
            print("[ShareExtension][DataService] ✅ Répertoire créé/vérifié")
        } catch {
            print("[ShareExtension][DataService] ❌ Erreur préparation: \(error)")
        }
    }
}
