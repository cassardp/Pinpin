//
//  MacSidebarMenu.swift
//  PinpinMac
//
//  Menu ellipsis en bas de la sidebar avec Liquid Glass (macOS 26)
//  Regroupe: Add Note, Add Category, Reorder Categories, Settings, About
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
            Section {
                Button {
                    onAddNote()
                } label: {
                    Label("Add Note", systemImage: "note.text.badge.plus")
                }
            }
            
            // MARK: - Category Actions
            Section {
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
            }
            
            // MARK: - App Actions
            Section {
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
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .medium))
        }
        .menuIndicator(.hidden)
        .buttonStyle(.borderless)
        .frame(width: 44, height: 44)
        .background(.regularMaterial, in: Circle())
        .overlay {
            Circle()
                .strokeBorder(.quaternary.opacity(0.5), lineWidth: 0.5)
        }
        .help("Menu")
    }
}
