//
//  PinpinMacApp.swift
//  PinpinMac
//
//  Application Mac complète avec fenêtre plein écran
//

import SwiftUI
import SwiftData

@main
struct PinpinMacApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([ContentItem.self, Category.self])
        let configuration = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(AppConstants.groupID),
            cloudKitDatabase: .private(AppConstants.cloudKitContainerID)
        )
        
        print("📦 Configuration SwiftData macOS:")
        print("   • App Group: \(AppConstants.groupID)")
        print("   • CloudKit Container: \(AppConstants.cloudKitContainerID)")
        print("   • CloudKit Database: .private")
        
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            print("✅ ModelContainer macOS créé avec succès")
            
            // Log le nombre d'items au démarrage
            Task { @MainActor in
                let context = container.mainContext
                let descriptor = FetchDescriptor<ContentItem>(sortBy: [SortDescriptor(\.createdAt)])
                if let items = try? context.fetch(descriptor) {
                    print("📊 Nombre d'items chargés (macOS): \(items.count)")
                }
            }
            
            return container
        } catch {
            fatalError("Impossible de créer ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MacMainView()
                .modelContainer(sharedModelContainer)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 800)
    }
}
