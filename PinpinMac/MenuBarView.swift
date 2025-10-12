//
//  MenuBarView.swift
//  PinpinMac
//
//  Vue Menu Bar pour Pinpin
//

import SwiftUI
import SwiftData

struct MenuBarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ContentItem.createdAt, order: .reverse) private var items: [ContentItem]
    @Environment(\.openWindow) private var openWindow

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
            print("📊 MenuBarView: \(items.count) items au démarrage")
        }
    }
}
