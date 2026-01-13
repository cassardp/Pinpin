//
//  PinpinApp.swift
//  Pinpin
//
//  Created by Patrice on 12/06/2025.
//

import SwiftUI
import SwiftData

@main
struct PinpinApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([ContentItem.self, Category.self])
        let configuration = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(AppConstants.groupID),
            cloudKitDatabase: .private(AppConstants.cloudKitContainerID)
        )

        print("📦 Configuration SwiftData iOS:")
        print("   • App Group: \(AppConstants.groupID)")
        print("   • CloudKit Container: \(AppConstants.cloudKitContainerID)")
        print("   • CloudKit Database: .private")

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            print("✅ ModelContainer créé avec succès")

            // Log le nombre d'items au démarrage
            Task { @MainActor in
                let context = container.mainContext
                let descriptor = FetchDescriptor<ContentItem>(sortBy: [SortDescriptor(\.createdAt)])
                if let items = try? context.fetch(descriptor) {
                    print("📊 Nombre d'items chargés (iOS): \(items.count)")
                }
            }

            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        // Enregistrer pour les notifications distantes CloudKit
        registerForRemoteNotifications()
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .modelContainer(sharedModelContainer)
                .font(.system(.body, design: .rounded))
                .onAppear {
                    // S'assurer que l'enregistrement est fait au démarrage
                    registerForRemoteNotifications()
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                print("🔄 App iOS revenue au premier plan - Triggering CloudKit sync check")
                // Re-register pour s'assurer que les notifications sont actives
                registerForRemoteNotifications()
                Task { @MainActor in
                    let context = sharedModelContainer.mainContext
                    let descriptor = FetchDescriptor<ContentItem>()
                    _ = try? context.fetch(descriptor)
                    print("✅ Sync check iOS completé")
                }
            }
        }
    }
    
    private func registerForRemoteNotifications() {
        // CloudKit utilise des notifications silencieuses (silent push)
        // Pas besoin d'autorisation utilisateur, juste l'enregistrement APNs
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
            print("📡 Registered for remote notifications (CloudKit)")
        }
    }
}
