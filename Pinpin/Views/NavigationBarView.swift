//
//  NavigationBarView.swift
//  Pinpin
//
//  Barre de navigation combinée avec recherche
//

import SwiftUI

struct NavigationBarView: View {
    // Bindings pour l'état
    @Binding var isSelectionMode: Bool
    @Binding var selectedItems: Set<UUID>
    @Binding var searchQuery: String
    @Binding var showSearchBar: Bool
    @Binding var isMenuOpen: Bool
    
    // Actions
    let onSelectAll: () -> Void
    let onDeleteSelected: () -> Void
    let filteredItemsCount: Int
    
    var body: some View {
        HStack {
            // Bouton Cancel (seulement visible en mode sélection)
            if isSelectionMode {
                Button(action: {
                    isSelectionMode = false
                    selectedItems.removeAll()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Bouton Edit/All/Delete
            Button(action: {
                if isSelectionMode {
                    if selectedItems.isEmpty {
                        onSelectAll()
                    } else {
                        onDeleteSelected()
                    }
                } else {
                    isSelectionMode = true
                }
            }) {
                HStack(spacing: 4) {
                    // Edit mode
                    if !isSelectionMode {
                        Text("Select")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.gray)
                        Image(systemName: "circle")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    // Select All mode
                    else if selectedItems.isEmpty {
                        Text("All")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.gray)
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    // Delete mode
                    else {
                        Text("\(selectedItems.count)")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.red)
                        Image(systemName: "trash")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 16)
        .padding(.top, 8)
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - Preview
#Preview {
    NavigationBarView(
        isSelectionMode: .constant(false),
        selectedItems: .constant([]),
        searchQuery: .constant(""),
        showSearchBar: .constant(false),
        isMenuOpen: .constant(false),
        onSelectAll: {},
        onDeleteSelected: {},
        filteredItemsCount: 10
    )
}
