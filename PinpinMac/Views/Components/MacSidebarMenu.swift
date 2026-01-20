//
//  MacSidebarMenu.swift
//  PinpinMac
//
//  Menu ellipsis en bas de la sidebar (similaire au menu iOS)
//  Regroupe: Add Note, Add Category, Edit Categories, Settings, About
//  Utilise le style Liquid Glass d'iOS 26 / macOS
//

import SwiftUI

struct MacSidebarMenu: View {
    // Actions
    let onAddNote: () -> Void
    let onAddCategory: () -> Void
    let onEditCategories: () -> Void
    let onSettings: () -> Void
    let onAbout: () -> Void
    
    var body: some View {
        Menu {
            // MARK: - Content Actions
            Button {
                onAddNote()
            } label: {
                Label("Add Note", systemImage: "note.text.badge.plus")
            }
            
            Divider()
            
            // MARK: - Category Actions
            Button {
                onAddCategory()
            } label: {
                Label("Add Category", systemImage: "folder.badge.plus")
            }
            
            Button {
                onEditCategories()
            } label: {
                Label("Reorder Categories", systemImage: "arrow.up.arrow.down")
            }
            
            Divider()
            
            // MARK: - App Actions
            Button {
                onSettings()
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
            
            Button {
                onAbout()
            } label: {
                Label("About", systemImage: "info.circle")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .medium))
        }
        .buttonStyle(.glass)
        .menuIndicator(.hidden)
        .help("Menu")
    }
}
