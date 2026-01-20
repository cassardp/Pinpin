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
            
            // MARK: - Selection Mode
            
            ToolbarItem(placement: .principal) {
                Spacer()
            }
            
            ToolbarItemGroup(placement: .automatic) {
                // Cancel Button
                Button(role: .close) {
                    selectionManager.toggleSelectionMode()
                } label: {
                    Image(systemName: "xmark")
                }
                .help("Cancel Selection")
                
                // Select All - visible uniquement si aucune sélection
                if !selectionManager.hasSelection {
                    Button {
                        selectionManager.selectAll(items: allItemIds)
                    } label: {
                        Text("Select All")
                            .font(.system(size: 12))
                    }
                }
                
                // Move to Category Menu avec compteur
                if selectionManager.hasSelection {
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
                
                // Delete Button avec compteur - rouge
                if selectionManager.hasSelection {
                    Button(role: .destructive) {
                        onDeleteSelected()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 13, weight: .medium))
                            Text("\(selectionManager.selectedCount)")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(Color(.systemRed))
                    }
                    .help("Delete \(selectionManager.selectedCount) item\(selectionManager.selectedCount > 1 ? "s" : "")")
                }
            }
        } else {
            // MARK: - Normal Mode
            
            // Spacer pour pousser à droite
            ToolbarItem(placement: .principal) {
                Spacer()
            }
            
            // Selection Mode Button - à droite de la toolbar
            ToolbarItem(placement: .automatic) {
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
