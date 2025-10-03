import SwiftUI

// MARK: - FloatingSearchBar
struct FloatingSearchBar: View {
    @Binding var searchQuery: String
    @Binding var showSearchBar: Bool
    @Binding var isSelectionMode: Bool
    @Binding var selectedItems: Set<UUID>
    @Binding var showSettings: Bool
    @Binding var isMenuOpen: Bool
    var menuSwipeProgress: CGFloat
    var scrollProgress: CGFloat
    @FocusState private var isSearchFocused: Bool
    @Namespace private var searchTransitionNS
    @State private var isAnimatingSearchOpen: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var hapticTrigger: Int = 0
    @State private var isCategoriesEditing: Bool = false

    // Data
    var selectedContentType: String?
    var totalPinsCount: Int = 0

    // Actions
    let onSelectAll: () -> Void
    let onDeleteSelected: () -> Void
    let onRestoreBar: () -> Void

    // Insets
    var bottomPadding: CGFloat = 12
    
    // Animation unifiée pour synchroniser tous les éléments
    private let unifiedAnimation = Animation.spring(response: 0.36, dampingFraction: 0.86, blendDuration: 0.08)

    var body: some View {
        // Seulement la barre de recherche/contrôles pour safeAreaInset
        ZStack {
            if showSearchBar {
                searchBar
                    .transition(.identity)
                    .onAppear {
                        // Synchronisation parfaite - pas de délai
                        isSearchFocused = true
                        isAnimatingSearchOpen = false
                    }
            } else {
                controlsRow
                    .transition(.opacity)
            }
        }
        .padding(.bottom, bottomPadding)
        // Toujours visible même lors de l'ouverture du menu
        .scaleEffect(isSelectionMode ? 1.0 : (1 - scrollProgress * 0.2)) // Réduction de la réduction de taille
        .offset(y: isSelectionMode ? 0 : scrollProgress * 16) // Réduction du décalage vertical
        .animation(unifiedAnimation, value: showSearchBar)
        .animation(unifiedAnimation, value: isAnimatingSearchOpen)
        .animation(.easeInOut(duration: 0.2), value: scrollProgress) // Animation fluide du scroll
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
        .alert("Confirm Deletion", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDeleteSelected()
            }
        } message: {
            Text("Are you sure you want to delete \(selectedItems.count) item\(selectedItems.count > 1 ? "s" : "")? This action cannot be undone.")
        }
        // Synchroniser l'état d'édition des catégories (provenant du FilterMenuView)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FilterMenuViewRequestEditCategories"))) { _ in
            isCategoriesEditing = true
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FilterMenuViewRequestCreateCategory"))) { _ in
            isCategoriesEditing = true
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FilterMenuViewRequestCloseEditing"))) { _ in
            isCategoriesEditing = false
        }
        .onChange(of: isMenuOpen) { _, open in
            if !open { isCategoriesEditing = false }
        }
    }
    
    // MARK: - Overlay séparé pour MainView
    func overlayView() -> some View {
        Group {
            if showSearchBar {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture { dismissSearch() }
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Placeholder
    private var placeholderText: String {
        if let selectedType = selectedContentType {
            // Catégorie spécifique sélectionnée
            let categoryName = selectedType.capitalized
            return "Search in \(categoryName)..."
        } else {
            // Catégorie "All"
            return "Search..."
        }
    }


    // MARK: - SearchBar
    private var searchBar: some View {
        ZStack(alignment: .bottom) {
            // Contenu de la barre de recherche au premier plan
            VStack(spacing: 0) {
                // Capsules de recherche prédéfinies (sans padding horizontal)
                if showSearchBar {
                    PredefinedSearchView(
                        searchQuery: $searchQuery,
                        selectedContentType: selectedContentType,
                        onSearchSelected: dismissSearch
                    )
                }

                // Barre de recherche principale (avec padding horizontal)
                HStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary.opacity(0.5))

                        ZStack(alignment: .leading) {
                            if searchQuery.isEmpty {
                                Text(placeholderText)
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.primary.opacity(0.5))
                            }
                            TextField("", text: $searchQuery)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.primary)
                        }
                            .focused($isSearchFocused)
                            .textFieldStyle(.plain)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .submitLabel(.search)
                            .onSubmit { dismissSearch() }

                        if !searchQuery.isEmpty {
                            Button {
                                hapticTrigger += 1
                                searchQuery = "" 
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(.ultraThinMaterial)
                            .background(
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(Color(UIColor.systemBackground).opacity(0.3))
                            )
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            .matchedGeometryEffect(id: "searchBackground", in: searchTransitionNS)
                    )
                    
                    // Bouton xmark pour fermer le clavier
                    Button {
                        hapticTrigger += 1
                        dismissSearch()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 48, height: 48)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .background(
                                        Circle()
                                            .fill(Color(UIColor.systemBackground).opacity(0.3))
                                    )
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                    }
                }
                .padding(.bottom, 12)
                .padding(.horizontal, 16) // Padding pour la barre de recherche seulement
            }
        }
    }

    // MARK: - Row compacte
    private var controlsRow: some View {
        HStack {
            // Gauche : Ellipsis menu / Cancel
            Group {
                if isSelectionMode {
                    Button(action: {
                        hapticTrigger += 1
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isSelectionMode = false
                            selectedItems.removeAll()
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 48, height: 48)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .background(
                                        Circle()
                                            .fill(Color(UIColor.systemBackground).opacity(0.3))
                                    )
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                    }
                } else if isCategoriesEditing {
                    Button(action: {
                        hapticTrigger += 1
                        NotificationCenter.default.post(name: Notification.Name("FilterMenuViewRequestCloseEditing"), object: nil)
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 48, height: 48)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .background(
                                        Circle()
                                            .fill(Color(UIColor.systemBackground).opacity(0.3))
                                    )
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                    }
                } else {
                    Menu {
                        Button {
                            hapticTrigger += 1
                            showSettings = true
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }

                        Divider()

                        Button {
                            hapticTrigger += 1
                            isMenuOpen = true
                            NotificationCenter.default.post(name: Notification.Name("FilterMenuViewRequestEditCategories"), object: nil)
                        } label: {
                            Label("Edit categories", systemImage: "pencil")
                        }

                        Button {
                            hapticTrigger += 1
                            isMenuOpen = true
                            NotificationCenter.default.post(name: Notification.Name("FilterMenuViewRequestCreateCategory"), object: nil)
                        } label: {
                            Label("Add category", systemImage: "plus")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 48, height: 48)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .background(
                                        Circle()
                                            .fill(Color(UIColor.systemBackground).opacity(0.3))
                                    )
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                    }
                    .menuStyle(.button)
                }
            }
            .opacity(isSelectionMode ? 1.0 : (scrollProgress < 0.5 ? 1.0 : 0.0)) // Reste visible en mode sélection
            // Si le menu est ouvert, pousser le bouton gauche à gauche et masquer le reste
            if isMenuOpen {
                Spacer()
            }

            // Centre : Search (masqué quand le menu est ouvert)
            if !isMenuOpen {
            Button(action: {
                hapticTrigger += 1
                
                // D'abord restaurer la barre à sa taille normale
                onRestoreBar()
                
                isAnimatingSearchOpen = true
                withAnimation(unifiedAnimation) {
                    showSearchBar = true
                }
                // Focus will be set in searchBar.onAppear with a slight delay
            }) {
                if searchQuery.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary.opacity(0.5))
                        Text("Search")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.primary.opacity(0.5))
                        Spacer()
                    }
                    .frame(height: 48)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity) // Étendre la zone visuelle du bouton
                    .contentTransition(.opacity)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.98)),
                        removal: .opacity.combined(with: .scale(scale: 0.98))
                    ))
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(.ultraThinMaterial)
                            .background(
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(Color(UIColor.systemBackground).opacity(0.3))
                            )
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            .matchedGeometryEffect(id: "searchBackground", in: searchTransitionNS)
                    )
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                        Text(searchQuery)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        Spacer()
                        
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .onTapGesture {
                                hapticTrigger += 1
                                
                                // Restaurer la barre à sa taille normale
                                onRestoreBar()
                                
                                withAnimation(unifiedAnimation) {
                                    searchQuery = ""
                                }
                            }
                    }
                    .frame(height: 48)
                    .padding(.horizontal, 22)
                    .frame(maxWidth: .infinity) // Étendre la zone visuelle du bouton
                    .contentTransition(.opacity)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.98)),
                        removal: .opacity.combined(with: .scale(scale: 0.98))
                    ))
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(.ultraThickMaterial)
                            .colorScheme(.dark)
                            .matchedGeometryEffect(id: "searchBackground", in: searchTransitionNS)
                    )
                }
            }
            .animation(unifiedAnimation, value: searchQuery)
            .frame(maxWidth: .infinity) // Prend toute la largeur disponible entre les boutons gauche et droit
            } // end if !isMenuOpen

            // Droite : Selection / Delete (masqué quand le menu est ouvert)
            if !isMenuOpen {
            Button(action: {
                hapticTrigger += 1
                
                if isSelectionMode {
                    if selectedItems.isEmpty {
                        onSelectAll()
                    } else {
                        showDeleteConfirmation = true
                    }
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
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
                                    .font(.system(size: 17))
                                    .foregroundColor(.white)
                                    .padding(.bottom, 1)
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
                .background(
                    Group {
                        if isSelectionMode && !selectedItems.isEmpty {
                            RoundedRectangle(cornerRadius: 22)
                                .fill(Color.red)
                                .stroke(.white.opacity(0.3), lineWidth: 0.5)
                        } else {
                            RoundedRectangle(cornerRadius: 22)
                                .fill(.ultraThinMaterial)
                                .background(
                                    RoundedRectangle(cornerRadius: 22)
                                        .fill(Color(UIColor.systemBackground).opacity(0.3))
                                )
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        }
                    }
                )
            }
            .opacity(isSelectionMode ? 1.0 : (scrollProgress < 0.5 ? 1.0 : 0.0)) // Reste visible en mode sélection
            } // end if !isMenuOpen
        }
        .padding(.horizontal, 28) // Padding pour les contrôles seulement
    }

    // MARK: - Helper
    private func dismissSearch() {
        withAnimation(unifiedAnimation) {
            showSearchBar = false
            isSearchFocused = false
            isAnimatingSearchOpen = false
        }
    }
}

