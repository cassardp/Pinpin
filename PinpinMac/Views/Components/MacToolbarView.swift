//
//  MacToolbarView.swift
//  PinpinMac
//
//  Toolbar native macOS avec états normal/selection
//  Mode normal: uniquement le bouton checkmark pour activer la sélection
//  Mode sélection: Cancel, Select All, Move, Delete
//

import SwiftUI

struct MacToolbarView: ToolbarContent {
    @Bindable var selectionManager: MacSelectionManager
    let categoryNames: [String]
    let allItemIds: [UUID]
    
    // Actions
    let onMoveToCategory: (String) -> Void
    let onDeleteSelected: () -> Void
    
    var body: some ToolbarContent {
        if selectionManager.isSelectionMode {
            // MARK: - Selection Mode
            
            // Cancel Button - à gauche de la toolbar
            ToolbarItem(placement: .navigation) {
                Button(role: .close) {
                    selectionManager.toggleSelectionMode()
                } label: {
                    Image(systemName: "xmark")
                }
                .help("Cancel Selection")
            }
            
            // Select All - visible uniquement si aucune sélection
            if !selectionManager.hasSelection {
                ToolbarItem(placement: .navigation) {
                    Button {
                        selectionManager.selectAll(items: allItemIds)
                    } label: {
                        Text("Select All")
                            .font(.system(size: 12))
                    }
                }
            }
            
            // Move to Category Menu avec compteur
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
                        HStack(spacing: 4) {
                            Text("\(selectionManager.selectedCount)")
                                .font(.system(size: 12, weight: .semibold))
                            Image(systemName: "folder")
                                .font(.system(size: 13, weight: .medium))
                        }
                    }
                    .help("Move \(selectionManager.selectedCount) item\(selectionManager.selectedCount > 1 ? "s" : "") to Category")
                }
            }
            
            // Delete Button avec compteur - rouge
            if selectionManager.hasSelection {
                ToolbarItem(placement: .primaryAction) {
                    Button(role: .destructive) {
                        onDeleteSelected()
                    } label: {
                        HStack(spacing: 4) {
                            Text("\(selectionManager.selectedCount)")
                                .font(.system(size: 12, weight: .semibold))
                            Image(systemName: "trash")
                                .font(.system(size: 13, weight: .medium))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .help("Delete \(selectionManager.selectedCount) item\(selectionManager.selectedCount > 1 ? "s" : "")")
                }
            }
        } else {
            // MARK: - Normal Mode
            
            // Selection Mode Button - à droite de la toolbar
            ToolbarItem(placement: .primaryAction) {
                Button {
                    selectionManager.toggleSelectionMode()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                }
                .help("Enter Selection Mode")
            }
        }
    }
}
