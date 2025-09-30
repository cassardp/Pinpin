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
    @Query private var items: [ContentItem]
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "pin.fill")
                    .foregroundStyle(.blue)
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
        }
        .frame(width: 250)
        .padding(.vertical, 8)
    }
}
