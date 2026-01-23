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
            
            // Maintenance et log au démarrage
            Task { @MainActor in
                let context = container.mainContext
                
                // Dédoublonner les catégories au démarrage
                DatabaseMaintenanceService.shared.performStartupMaintenance(context: context)
                
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

    init() {
        // Enregistrer pour les notifications distantes CloudKit
        // CloudKit utilise des notifications silencieuses (silent push)
        // Pas besoin d'autorisation utilisateur, juste l'enregistrement APNs
        DispatchQueue.main.async {
            NSApplication.shared.registerForRemoteNotifications()
            print("📡 Registered for remote notifications (CloudKit macOS)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MacMainView()
                .modelContainer(sharedModelContainer)
                .preferredColorScheme(.light)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 800)
    }
    
}
