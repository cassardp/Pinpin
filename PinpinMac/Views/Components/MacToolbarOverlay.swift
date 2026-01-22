//
//  MacToolbarOverlay.swift
//  PinpinMac
//
//  Overlay flottant en bas de page avec Liquid Glass (macOS 26)
//  Mode normal: recherche + bouton de sélection
//  Mode sélection: Cancel, Select All, Move, Delete
//

import SwiftUI

struct MacToolbarOverlay: View {
    @Bindable var selectionManager: MacSelectionManager
    let categoryNames: [String]
    let allItemIds: [UUID]
    
    // Actions
    let onMoveToCategory: (String) -> Void
    let onDeleteSelected: () -> Void
    let onAddNote: () -> Void
    
    // Search
    @Binding var searchQuery: String
    
    // États
    @State private var showDeleteConfirmation: Bool = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Bouton Add Note - seulement en mode normal
            if !selectionManager.isSelectionMode {
                Button {
                    onAddNote()
                } label: {
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 15, weight: .medium))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.borderless)
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(.quaternary.opacity(0.5), lineWidth: 0.5)
                }
                .help("Add Note")
            }
            
            // Barre de recherche avec Liquid Glass - seulement en mode normal
            if !selectionManager.isSelectionMode {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    TextField("Search...", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 15))
                    
                    if !searchQuery.isEmpty {
                        Button {
                            searchQuery = ""
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(height: 44)
                .padding(.horizontal, 18)
                .background(.regularMaterial, in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(.quaternary.opacity(0.5), lineWidth: 0.5)
                }
            }
            
            // Boutons avec Liquid Glass
            Group {
                if selectionManager.isSelectionMode {
                    // Mode sélection
                    HStack(spacing: 10) {
                        if !selectionManager.hasSelection {
                            // Select All
                            Button {
                                selectionManager.selectAll(items: allItemIds)
                            } label: {
                                Text("Select All")
                                    .font(.system(size: 14, weight: .regular))
                                    .frame(height: 44)
                                    .frame(maxWidth: 120)
                            }
                            .buttonStyle(.borderless)
                            .frame(height: 44)
                            .padding(.horizontal, 16)
                            .background(.regularMaterial, in: Capsule())
                            .overlay {
                                Capsule()
                                    .strokeBorder(.quaternary.opacity(0.5), lineWidth: 0.5)
                            }
                        } else {
                            // Move to Category
                            Menu {
                                ForEach(categoryNames, id: \.self) { categoryName in
                                    Button {
                                        onMoveToCategory(categoryName)
                                    } label: {
                                        Label(categoryName, systemImage: "folder")
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "folder")
                                        .font(.system(size: 13, weight: .medium))
                                    Text("\(selectionManager.selectedCount)")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .frame(height: 44)
                            }
                            .menuIndicator(.hidden)
                            .buttonStyle(.borderless)
                            .frame(height: 44)
                            .padding(.horizontal, 14)
                            .background(.regularMaterial, in: Capsule())
                            .overlay {
                                Capsule()
                                    .strokeBorder(.quaternary.opacity(0.5), lineWidth: 0.5)
                            }
                            
                            // Delete
                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 13, weight: .medium))
                                    Text("\(selectionManager.selectedCount)")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundStyle(.white)
                                .frame(height: 44)
                            }
                            .buttonStyle(.borderless)
                            .frame(height: 44)
                            .padding(.horizontal, 14)
                            .background(.red.gradient, in: Capsule())
                            .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        
                        // Cancel
                        Button {
                            selectionManager.toggleSelectionMode()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .medium))
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.borderless)
                        .frame(width: 44, height: 44)
                        .background(.regularMaterial, in: Circle())
                        .overlay {
                            Circle()
                                .strokeBorder(.quaternary.opacity(0.5), lineWidth: 0.5)
                        }
                    }
                } else {
                    // Mode normal - bouton sélection
                    Button {
                        selectionManager.toggleSelectionMode()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.borderless)
                    .frame(width: 44, height: 44)
                    .background(.regularMaterial, in: Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(.quaternary.opacity(0.5), lineWidth: 0.5)
                    }
                }
            }
            .animation(.smooth(duration: 0.25), value: selectionManager.isSelectionMode)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
        .frame(maxWidth: 500) // Limite la largeur maximale
        .alert("Confirm Deletion", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive, action: onDeleteSelected)
        } message: {
            Text("Are you sure you want to delete \(selectionManager.selectedCount) item\(selectionManager.selectedCount > 1 ? "s" : "")?")
        }
    }
}
