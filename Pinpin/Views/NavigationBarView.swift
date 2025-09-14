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
        // Barre de navigation principale (sans recherche)
        HStack {
            // Bouton catégorie/Cancel à gauche
            Button(action: {
                if isSelectionMode {
                    // Mode sélection : Cancel
                    isSelectionMode = false
                    selectedItems.removeAll()
                } else {
                    // Mode normal : ouvrir le menu
                    isMenuOpen = true
                }
            }) {
                Text(isSelectionMode ? "Cancel" : "")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.gray)
            }
            
            
            Spacer()
            
            // Bouton Select/Delete/All à droite
            Button(action: {
                if isSelectionMode {
                    if selectedItems.isEmpty {
                        // Aucun sélectionné -> sélectionner tout
                        onSelectAll()
                    } else {
                        // Supprimer la sélection
                        onDeleteSelected()
                    }
                } else {
                    // Mode normal : activer la sélection
                    isSelectionMode = true
                }
            }) {
                Text(
                    isSelectionMode
                    ? (selectedItems.isEmpty ? "All" : "Delete • \(selectedItems.count)")
                    : "Edit"
                )
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(isSelectionMode && !selectedItems.isEmpty ? .red : .gray)
            }
        }
        .padding(.horizontal, 0)
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
