//
//  MacToolbarView.swift
//  PinpinMac
//
//  Toolbar native macOS avec états normal/selection
//

import SwiftUI

struct MacToolbarView: ToolbarContent {
    @Bindable var selectionManager: MacSelectionManager
    let isSidebarVisible: Bool
    let categoryNames: [String]
    let allItemIds: [UUID]
    
    // Actions
    let onAddNote: () -> Void
    let onAddCategory: () -> Void
    let onSettings: () -> Void
    let onAbout: () -> Void
    let onMoveToCategory: (String) -> Void
    let onDeleteSelected: () -> Void
    
    var body: some ToolbarContent {
        if selectionManager.isSelectionMode {
            // MARK: - Selection Mode
            
            // Cancel Button
            ToolbarItem(placement: .navigation) {
                Button {
                    withAnimation(.snappy(duration: 0.25)) {
                        selectionManager.toggleSelectionMode()
                    }
                } label: {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 14, weight: .medium))
                }
                .help("Cancel Selection")
            }
            
            // Select All / Deselect All
            ToolbarItem(placement: .navigation) {
                if selectionManager.hasSelection {
                    Button {
                        selectionManager.deselectAll()
                    } label: {
                        Text("Deselect All")
                            .font(.system(size: 12))
                    }
                } else {
                    Button {
                        selectionManager.selectAll(items: allItemIds)
                    } label: {
                        Text("Select All")
                            .font(.system(size: 12))
                    }
                }
            }
            
            // Selection Count (center)
            ToolbarItem(placement: .principal) {
                if selectionManager.hasSelection {
                    Text("\(selectionManager.selectedCount) selected")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                } else {
                    Text("Select items")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }
            
            // Move to Category Menu
            if selectionManager.hasSelection {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        ForEach(categoryNames, id: \.self) { categoryName in
                            Button {
                                onMoveToCategory(categoryName)
                            } label: {
                                Label(categoryName, systemImage: "folder")
                            }
                        }
                    } label: {
                        Label("Move", systemImage: "folder")
                            .font(.system(size: 12))
                    }
                    .help("Move to Category")
                }
            }
            
            // Delete Button
            if selectionManager.hasSelection {
                ToolbarItem(placement: .primaryAction) {
                    Button(role: .destructive) {
                        onDeleteSelected()
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .font(.system(size: 12))
                    }
                    .help("Delete Selected Items")
                }
            }
        } else {
            // MARK: - Normal Mode
            
            // Settings Menu
            ToolbarItem(placement: .navigation) {
                MacSettingsMenu(
                    onSettings: onSettings,
                    onAbout: onAbout
                )
            }
            
            // Add Menu
            ToolbarItem(placement: .navigation) {
                MacAddMenu(
                    isSidebarVisible: isSidebarVisible,
                    onAddNote: onAddNote,
                    onAddCategory: onAddCategory
                )
            }
            
            // Selection Mode Button
            ToolbarItem(placement: .primaryAction) {
                Button {
                    withAnimation(.snappy(duration: 0.25)) {
                        selectionManager.toggleSelectionMode()
                    }
                } label: {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 14, weight: .medium))
                }
                .help("Enter Selection Mode")
            }
        }
    }
}
