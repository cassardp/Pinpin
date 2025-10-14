//
//  PinpinMacApp.swift
//  PinpinMac
//
//  Created by Patrice on 30/09/2025.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct PinpinMacApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

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
            print("✅ ModelContainer créé avec succès")
            return container
        } catch {
            fatalError("Impossible de créer ModelContainer: \(error)")
        }
    }()

    init() {
        // Passer le container à AppDelegate
        appDelegate.modelContainer = sharedModelContainer
    }

    var body: some Scene {
        // Menu Bar App (pas de fenêtre par défaut)
        MenuBarExtra("Pinpin", image: "MenuBarIcon") {
            MenuBarView()
                .modelContainer(sharedModelContainer)
        }
        .menuBarExtraStyle(.window)

        // Fenêtre optionnelle (cachée par défaut)
        WindowGroup(id: "main") {
            ContentView()
                .modelContainer(sharedModelContainer)
        }
        .defaultSize(width: 800, height: 600)
    }
}

// AppDelegate pour cacher l'icône du Dock
class AppDelegate: NSObject, NSApplicationDelegate {
    var modelContainer: ModelContainer?

    func checkiCloudStatus() {
        // Vérifier si iCloud est disponible
        if let ubiquityToken = FileManager.default.ubiquityIdentityToken {
            print("✅ iCloud est disponible et connecté")
            print("   Token: \(ubiquityToken)")
        } else {
            print("❌ iCloud n'est PAS disponible ou non connecté")
            print("   L'utilisateur doit se connecter à iCloud dans les Réglages Système")
        }

        // Vérifier l'accès au container iCloud spécifique
        if let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: AppConstants.cloudKitContainerID) {
            print("✅ Container iCloud accessible: \(containerURL.path)")
        } else {
            print("❌ Container iCloud NON accessible: \(AppConstants.cloudKitContainerID)")
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Cacher l'icône du Dock (Menu Bar App uniquement)
        NSApp.setActivationPolicy(.accessory)

        // Vérifier le statut iCloud
        checkiCloudStatus()

        // Demander la permission pour les notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("✅ Notifications autorisées (macOS)")
            }
        }

        // 🔧 Force CloudKit sync initialization
        // Sans ça, le premier item ajouté peut ne pas sync
        Task { @MainActor in
            guard let container = self.modelContainer else {
                print("⚠️ ModelContainer non disponible")
                return
            }

            let context = container.mainContext

            // Force un fetch pour "réveiller" CloudKit
            let descriptor = FetchDescriptor<ContentItem>(sortBy: [SortDescriptor(\.createdAt)])
            if let items = try? context.fetch(descriptor) {
                print("🔧 CloudKit initialisé au démarrage")
                print("📊 Nombre d'items chargés: \(items.count)")

                // Afficher les détails des items pour debug
                for (index, item) in items.prefix(5).enumerated() {
                    print("   Item \(index + 1): \(item.title) - créé le \(item.createdAt)")
                }

                if items.count > 5 {
                    print("   ... et \(items.count - 5) autres items")
                }
            } else {
                print("⚠️ Impossible de charger les items")
            }
        }
    }
}
