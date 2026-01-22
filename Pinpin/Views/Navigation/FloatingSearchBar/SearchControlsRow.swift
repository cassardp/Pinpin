import SwiftUI

// MARK: - SearchControlsRow
struct SearchControlsRow: View {
    // MARK: - Bindings
    @Binding var searchQuery: String
    @Binding var isSelectionMode: Bool
    @Binding var selectedItems: Set<UUID>
    @Binding var showDeleteConfirmation: Bool
    @Binding var isMenuOpen: Bool
    @Binding var isAnimatingSearchOpen: Bool
    
    // MARK: - Properties
    var scrollProgress: CGFloat
    var availableCategories: [String]
    var currentCategory: String?
    var searchTransitionNS: Namespace.ID
    var isEditingCategories: Bool
    
    // MARK: - Actions
    let onSelectAll: () -> Void
    let onMoveToCategory: (String) -> Void
    let onRestoreBar: () -> Void
    let onCreateNote: () -> Void
    let onOpenSearch: () -> Void
    let onHaptic: () -> Void
    
    // MARK: - Constants
    private let unifiedAnimation = Animation.smooth(duration: 0.36)
    
    private enum NotificationName {
        static let createCategory = Notification.Name("FilterMenuViewRequestCreateCategory")
        static let toggleEditCategories = Notification.Name("FilterMenuViewRequestToggleEditCategories")
    }
    
    var body: some View {
        HStack {
            // Gauche : Ellipsis menu / Cancel
            Group {
                if isSelectionMode {
                    CircularButton(
                        icon: "xmark",
                        action: {
                            onHaptic()
                            withAnimation(.smooth(duration: 0.3)) {
                                isSelectionMode = false
                                selectedItems.removeAll()
                            }
                        }
                    )

                } else if isMenuOpen {
                    // Quand le menu catégorie est ouvert: boutons "Add Category" + "Edit"
                    HStack(spacing: 12) {
                        CircularButton(
                            icon: "plus",
                            action: {
                                onHaptic()
                                NotificationCenter.default.post(name: NotificationName.createCategory, object: nil)
                            }
                        )
                        
                        CircularButton(
                            icon: isEditingCategories ? "checkmark" : "pencil",
                            action: {
                                onHaptic()
                                NotificationCenter.default.post(name: NotificationName.toggleEditCategories, object: nil)
                            }
                        )
                    }
                } else {
                    // Quand le menu est fermé: bouton "Add Note"
                    CircularButton(
                        icon: "text.alignleft",
                        action: {
                            onHaptic()
                            onCreateNote()
                        }
                    )
                }
            }
            .opacity(isMenuOpen || isSelectionMode ? 1 : (scrollProgress > 0.5 ? 0 : CGFloat(1 - (scrollProgress * 2))))
            
            // Si le menu est ouvert, pousser les boutons à gauche
            if isMenuOpen {
                Spacer()
            }
            
            // Centre : Search ou Move (masqué quand le menu est ouvert)
            if !isMenuOpen {
                if isSelectionMode {
                    Spacer()
                    
                    if !selectedItems.isEmpty {
                        // Bouton Move en mode sélection avec items
                        MoveToCategoryMenu(
                            selectedItems: selectedItems,
                            availableCategories: availableCategories,
                            currentCategory: currentCategory,
                            onMoveToCategory: onMoveToCategory,
                            onHaptic: onHaptic
                        )
                    }
                } else {
                    // Bouton Search normal
                    Button(action: onOpenSearch) {
                        if searchQuery.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: scrollProgress > 0.5 ? 20 : 18, weight: .medium))
                                    .foregroundColor(scrollProgress > 0.5 ? .primary : .primary.opacity(0.4))
                                    .matchedGeometryEffect(id: "searchIcon", in: searchTransitionNS)
                                
                                if scrollProgress < 0.5 {
                                    Text("Search")
                                        .font(.system(size: 17, weight: .regular))
                                        .foregroundColor(.primary.opacity(0.4))
                                        .opacity(CGFloat(1 - (scrollProgress * 2)))
                                    Spacer()
                                }
                            }
                            .frame(height: scrollProgress > 0.5 ? 54 : 48)
                            .padding(.horizontal, scrollProgress > 0.5 ? 0 : CGFloat(24 - (24 * scrollProgress * 2)))
                            .frame(maxWidth: scrollProgress > 0.5 ? 54 : .infinity)
                            .scaleEffect(isAnimatingSearchOpen ? 0.95 : 1.0)
                            .contentTransition(.opacity)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.98)),
                                removal: .opacity.combined(with: .scale(scale: 0.98))
                            ))
                            .glassEffect()
                            .glassEffectID("searchBackground", in: searchTransitionNS)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Text(searchQuery)
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                
                                Spacer()
                                
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .onTapGesture {
                                        onHaptic()
                                        
                                        // Restaurer la barre à sa taille normale
                                        onRestoreBar()
                                        
                                        withAnimation(unifiedAnimation) {
                                            searchQuery = ""
                                        }
                                    }
                            }
                            .frame(height: 48)
                            .padding(.horizontal, 22)
                            .frame(maxWidth: .infinity)
                            .contentTransition(.opacity)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.98)),
                                removal: .opacity.combined(with: .scale(scale: 0.98))
                            ))
                            .glassEffect(.regular.tint(.black))
                            .colorScheme(.dark)
                            .glassEffectID("searchBackground", in: searchTransitionNS)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        }
                    }
                    .animation(unifiedAnimation, value: searchQuery)
                    .frame(maxWidth: searchQuery.isEmpty && scrollProgress > 0.5 ? 54 : .infinity)
                }
            } // end if !isMenuOpen
            
            // Droite : Selection / Delete (masqué quand le menu est ouvert)
            if !isMenuOpen {
                SelectionActionsButton(
                    isSelectionMode: $isSelectionMode,
                    selectedItems: $selectedItems,
                    showDeleteConfirmation: $showDeleteConfirmation,
                    scrollProgress: scrollProgress,
                    onSelectAll: onSelectAll,
                    onHaptic: onHaptic
                )
            } // end if !isMenuOpen
        }
        .padding(.horizontal, 28)
    }
}

// MARK: - Supporting Views

private struct CircularButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            CircularButtonContent(icon: icon)
        }
    }
}

private struct CircularButtonContent: View {
    let icon: String
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(.primary)
            .frame(width: 48, height: 48)
            .floatingButtonBackground()
    }
}

// MARK: - SelectionActionsButton
private struct SelectionActionsButton: View {
    @Binding var isSelectionMode: Bool
    @Binding var selectedItems: Set<UUID>
    @Binding var showDeleteConfirmation: Bool
    
    var scrollProgress: CGFloat
    let onSelectAll: () -> Void
    let onHaptic: () -> Void
    
    var body: some View {
        Button(action: {
            onHaptic()
            
            if isSelectionMode {
                if selectedItems.isEmpty {
                    onSelectAll()
                } else {
                    showDeleteConfirmation = true
                }
            } else {
                withAnimation(.smooth(duration: 0.3)) {
                    isSelectionMode = true
                }
            }
        }) {
            Group {
                if isSelectionMode {
                    if selectedItems.isEmpty {
                        Text("All")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.primary)
                    } else {
                        HStack(spacing: 4) {
                            Text("\(selectedItems.count)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            Image(systemName: "trash")
                                .font(.system(size: 19))
                                .foregroundColor(.white)
                        }
                    }
                } else {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            .frame(height: 48)
            .frame(minWidth: 48)
            .padding(.horizontal, isSelectionMode ? 8 : 0)
            .floatingButtonBackground(isHighlighted: isSelectionMode && !selectedItems.isEmpty)
        }
        .opacity(isSelectionMode ? 1 : (scrollProgress > 0.5 ? 0 : CGFloat(1 - (scrollProgress * 2))))
    }
}

// MARK: - MoveToCategoryMenu
private struct MoveToCategoryMenu: View {
    var selectedItems: Set<UUID>
    var availableCategories: [String]
    var currentCategory: String?
    
    let onMoveToCategory: (String) -> Void
    let onHaptic: () -> Void
    
    var body: some View {
        Menu {
            ForEach(availableCategories.reversed(), id: \.self) { category in
                Button {
                    onHaptic()
                    onMoveToCategory(category)
                } label: {
                    Label(category.capitalized, systemImage: "folder")
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text("\(selectedItems.count)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                Image(systemName: "folder")
                    .font(.system(size: 19))
                    .foregroundColor(.primary)
            }
            .frame(height: 48)
            .frame(minWidth: 48)
            .padding(.horizontal, 8)
            .floatingButtonBackground()
        }
        .menuStyle(.button)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.98)),
            removal: .opacity.combined(with: .scale(scale: 0.98))
        ))
    }
}
