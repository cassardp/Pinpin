//
//  MenuBarView.swift
//  PinpinMac
//
//  Vue Menu Bar pour Pinpin
//

import SwiftUI
import SwiftData
import UserNotifications

struct MenuBarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ContentItem.createdAt, order: .reverse) private var items: [ContentItem]
    @Environment(\.openWindow) private var openWindow
    
    @State private var lastItemCount = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("Pinpin")
                    .font(.headline)
                Spacer()
                Text("\(items.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
            .padding(8)
        }
        .frame(width: 250)
        .padding(.vertical, 8)
        .onAppear {
            lastItemCount = items.count
            print("📊 MenuBarView: \(items.count) items au démarrage")
        }
        .onChange(of: items.count) { oldValue, newValue in
            let addedItems = newValue - oldValue
            if addedItems > 0 {
                print("✅ Nouveaux items détectés: \(addedItems) (de \(oldValue) à \(newValue))")
                Task {
                    await showNotification(count: addedItems)
                }
            }
        }
    }
    
    private func showNotification(count: Int) async {
        let center = UNUserNotificationCenter.current()
        
        // Vérifier la permission
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            print("⚠️ Notifications non autorisées")
            return
        }
        
        // Créer la notification
        let content = UNMutableNotificationContent()
        content.title = "Added to Pinpin"
        content.body = count == 1 ? "1 new item" : "\(count) new items"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        do {
            try await center.add(request)
            print("✅ Notification système affichée: \(count) item(s)")
        } catch {
            print("❌ Erreur notification: \(error)")
        }
    }
}
