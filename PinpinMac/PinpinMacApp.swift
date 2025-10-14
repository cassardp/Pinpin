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

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
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

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Cacher l'icône du Dock (Menu Bar App uniquement)
        NSApp.setActivationPolicy(.accessory)

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
            _ = try? context.fetch(descriptor)
            print("🔧 CloudKit initialisé au démarrage")
        }
    }
}
