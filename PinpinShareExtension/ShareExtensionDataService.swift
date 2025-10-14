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
        let schema = Schema([ContentItem.self, Category.self])
        let configuration = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(AppConstants.groupID),
            cloudKitDatabase: .private(AppConstants.cloudKitContainerID)
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Impossible de créer ModelContainer dans l'extension: \(error)")
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
            return ["Misc"] // Fallback
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
}
