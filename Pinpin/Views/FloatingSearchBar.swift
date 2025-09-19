import SwiftUI

// MARK: - FloatingSearchBar
struct FloatingSearchBar: View {
    @Binding var searchQuery: String
    @Binding var showSearchBar: Bool
    @Binding var isSelectionMode: Bool
    @Binding var selectedItems: Set<UUID>
    @Binding var showSettings: Bool
    var menuSwipeProgress: CGFloat
    var scrollProgress: CGFloat
    @FocusState private var isSearchFocused: Bool
    @Namespace private var searchTransitionNS
    @State private var isAnimatingSearchOpen: Bool = false
    @State private var showDeleteConfirmation: Bool = false

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
                    .transition(.opacity)
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
        .opacity(1 - menuSwipeProgress) // Seulement le menu affecte l'opacity
        .scaleEffect(isSelectionMode ? 1.0 : (1 - scrollProgress * 0.2)) // Pas de scale en mode sélection
        .offset(y: isSelectionMode ? 0 : scrollProgress * 30) // Pas de décalage en mode sélection
        .animation(unifiedAnimation, value: showSearchBar)
        .animation(unifiedAnimation, value: isAnimatingSearchOpen)
        .animation(.easeInOut(duration: 0.2), value: scrollProgress) // Animation fluide du scroll
        .alert("Confirm Deletion", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDeleteSelected()
            }
        } message: {
            Text("Are you sure you want to delete \(selectedItems.count) item\(selectedItems.count > 1 ? "s" : "")? This action cannot be undone.")
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
            if totalPinsCount > 0 {
                return "Search in your \(totalPinsCount) pin\(totalPinsCount > 1 ? "s" : "")..."
            } else {
                return "Search in your pins..."
            }
        }
    }


    // MARK: - SearchBar
    private var searchBar: some View {
        VStack(spacing: 0) {
            // Capsules de recherche prédéfinies (sans padding horizontal)
            PredefinedSearchView(searchQuery: $searchQuery, onSearchSelected: dismissSearch)
            
            // Barre de recherche principale (avec padding horizontal)
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)

                ZStack(alignment: .leading) {
                    if searchQuery.isEmpty {
                        Text(placeholderText)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    TextField("", text: $searchQuery)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.white)
                }
                    .focused($isSearchFocused)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .submitLabel(.search)
                    .onSubmit { dismissSearch() }

                if !searchQuery.isEmpty {
                    Button { searchQuery = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.thinMaterial)
                    .colorScheme(.dark) // Force le mode sombre pour un look cohérent
                    .matchedGeometryEffect(id: "searchBackground", in: searchTransitionNS)
            )
            .padding(.bottom, 12)
            .padding(.horizontal, 16) // Padding pour la barre de recherche seulement
        }
    }

    // MARK: - Row compacte
    private var controlsRow: some View {
        HStack {
            Spacer()

            // Gauche : Settings / Cancel
            Button(action: {
                if isSelectionMode {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isSelectionMode = false
                        selectedItems.removeAll()
                    }
                } else {
                    showSettings = true
                }
            }) {
                Image(systemName: isSelectionMode ? "xmark" : "slider.vertical.3")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(.thinMaterial)
                    )
            }
            .opacity(isSelectionMode ? 1.0 : (scrollProgress < 0.5 ? 1.0 : 0.0)) // Reste visible en mode sélection

            // Centre : Search
            Button(action: {
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
                            .foregroundColor(.primary)
                        Text("Search")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .contentTransition(.opacity)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.98)),
                        removal: .opacity.combined(with: .scale(scale: 0.98))
                    ))
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(.thinMaterial)
                            .matchedGeometryEffect(id: "searchBackground", in: searchTransitionNS)
                    )
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                        Text(searchQuery)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .onTapGesture {
                                // Restaurer la barre à sa taille normale
                                onRestoreBar()
                                
                                withAnimation(unifiedAnimation) {
                                    searchQuery = ""
                                }
                            }
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .contentTransition(.opacity)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.98)),
                        removal: .opacity.combined(with: .scale(scale: 0.98))
                    ))
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(.thinMaterial)
                            .colorScheme(.dark)
                            .matchedGeometryEffect(id: "searchBackground", in: searchTransitionNS)
                    )
                }
            }
            .animation(unifiedAnimation, value: searchQuery)

            // Droite : Selection / Delete
            Button(action: {
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
                        } else {
                            RoundedRectangle(cornerRadius: 22)
                                .fill(.thinMaterial)
                        }
                    }
                )
            }
            .opacity(isSelectionMode ? 1.0 : (scrollProgress < 0.5 ? 1.0 : 0.0)) // Reste visible en mode sélection

            Spacer()
        }
        .padding(.horizontal, 16) // Padding pour les contrôles seulement
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

