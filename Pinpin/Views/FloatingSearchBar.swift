import SwiftUI

// MARK: - FloatingSearchBar
struct FloatingSearchBar: View {
    // MARK: - Bindings
    @Binding var searchQuery: String
    @Binding var showSearchBar: Bool
    @Binding var isSelectionMode: Bool
    @Binding var selectedItems: Set<UUID>
    @Binding var showSettings: Bool
    @Binding var isMenuOpen: Bool
    
    // MARK: - Properties
    var menuSwipeProgress: CGFloat
    var scrollProgress: CGFloat
    var selectedContentType: String?
    var totalPinsCount: Int = 0
    var bottomPadding: CGFloat = 12
    var availableCategories: [String] = []

    // MARK: - Actions
    let onSelectAll: () -> Void
    let onDeleteSelected: () -> Void
    let onRestoreBar: () -> Void
    let onMoveToCategory: (String) -> Void
    
    // MARK: - State
    @FocusState private var isSearchFocused: Bool
    @Namespace private var searchTransitionNS
    @State private var isAnimatingSearchOpen: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var hapticTrigger: Int = 0
    @State private var isCategoriesEditing: Bool = false
    
    // MARK: - Constants
    private let unifiedAnimation = Animation.spring(response: 0.36, dampingFraction: 0.86, blendDuration: 0.08)
    private let scrollAnimation = Animation.easeInOut(duration: 0.2)
    
    private enum NotificationName {
        static let editCategories = Notification.Name("FilterMenuViewRequestEditCategories")
        static let createCategory = Notification.Name("FilterMenuViewRequestCreateCategory")
        static let closeEditing = Notification.Name("FilterMenuViewRequestCloseEditing")
    }

    var body: some View {
        // Seulement la barre de recherche/contrôles pour safeAreaInset
        ZStack {
            if showSearchBar {
                searchBar
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.96, anchor: .bottom)).combined(with: .move(edge: .bottom)),
                        removal: .opacity.combined(with: .scale(scale: 0.96, anchor: .bottom))
                    ))
                    .onAppear {
                        // Synchronisation parfaite - pas de délai
                        isSearchFocused = true
                        isAnimatingSearchOpen = false
                    }
            } else {
                controlsRow
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.96)),
                        removal: .opacity.combined(with: .scale(scale: 0.96))
                    ))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, bottomPadding)
        .background(
            VStack(spacing: 0) {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: Color.primary.opacity(0.02), location: 0.4),
                        .init(color: Color.primary.opacity(0.06), location: 0.6),
                        .init(color: Color.primary.opacity(0.12), location: 0.75),
                        .init(color: Color.primary.opacity(0.22), location: 0.9),
                        .init(color: Color.primary.opacity(0.35), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity)
            .ignoresSafeArea()
        )
        .animation(unifiedAnimation, value: showSearchBar)
        .animation(unifiedAnimation, value: isAnimatingSearchOpen)
        .animation(scrollAnimation, value: scrollProgress)
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
        .alert("Confirm Deletion", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive, action: onDeleteSelected)
        } message: {
            Text(deleteConfirmationMessage)
        }
        .onReceive(NotificationCenter.default.publisher(for: NotificationName.editCategories)) { _ in
            isCategoriesEditing = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NotificationName.createCategory)) { _ in
            isCategoriesEditing = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NotificationName.closeEditing)) { _ in
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

    // MARK: - Computed Properties
    private var placeholderText: String {
        if let selectedType = selectedContentType {
            return "Search in \(selectedType.capitalized)..."
        }
        return "Search..."
    }
    
    private var deleteConfirmationMessage: String {
        "Are you sure you want to delete \(selectedItems.count) item\(selectedItems.count > 1 ? "s" : "")? This action cannot be undone."
    }
    
    private var shouldShowControls: Bool {
        isSelectionMode || scrollProgress < 0.5
    }


    // MARK: - SearchBar
    private var searchBar: some View {
        VStack(spacing: 0) {
                // Capsules de recherche prédéfinies (sans padding horizontal)
                if showSearchBar {
                    PredefinedSearchView(
                        searchQuery: $searchQuery,
                        selectedContentType: selectedContentType,
                        onSearchSelected: dismissSearch
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
                }

                // Barre de recherche principale (avec padding horizontal)
                HStack(spacing: 8) {
                    HStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary.opacity(0.4))

                        ZStack(alignment: .leading) {
                            if searchQuery.isEmpty {
                                Text(placeholderText)
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.primary.opacity(0.4))
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
                    .frame(height: 48)
                    .padding(.horizontal, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(.regularMaterial)
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
                                    .fill(.regularMaterial)
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                    }
                }
                .padding(.bottom, 12)
                .padding(.horizontal, 12) // Padding pour la barre de recherche seulement
        }
    }

    // MARK: - Row compacte
    private var controlsRow: some View {
        HStack {
            // Gauche : Ellipsis menu / Cancel
            Group {
                if isSelectionMode {
                    CircularButton(
                        icon: "xmark",
                        action: {
                            hapticTrigger += 1
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isSelectionMode = false
                                selectedItems.removeAll()
                            }
                        }
                    )
                } else if isCategoriesEditing {
                    CircularButton(
                        icon: "xmark",
                        action: {
                            hapticTrigger += 1
                            NotificationCenter.default.post(name: NotificationName.closeEditing, object: nil)
                        }
                    )
                } else {
                    Menu {
                        ControlGroup {
                            Button {
                                hapticTrigger += 1
                                showSettings = true
                            } label: {
                                Label("Settings", systemImage: "gearshape.fill")
                            }
                            Spacer()
                        }

                        Divider()

                        Button {
                            hapticTrigger += 1
                            NotificationCenter.default.post(name: NotificationName.editCategories, object: nil)
                        } label: {
                            Label("Edit categories", systemImage: "pencil")
                        }

                        Button {
                            hapticTrigger += 1
                            NotificationCenter.default.post(name: NotificationName.createCategory, object: nil)
                        } label: {
                            Label("Add category", systemImage: "plus")
                        }
                    } label: {
                        CircularButtonContent(icon: "ellipsis")
                    }
                    .menuStyle(.button)
                }
            }
            .opacity(isMenuOpen || isSelectionMode ? 1 : (scrollProgress > 0.5 ? 0 : CGFloat(1 - (scrollProgress * 2))))
            // Si le menu est ouvert, pousser le bouton gauche à gauche et masquer le reste
            if isMenuOpen {
                Spacer()
            }

            // Centre : Search ou Move (masqué quand le menu est ouvert)
            if !isMenuOpen {
                if isSelectionMode {
                    if !selectedItems.isEmpty {
                        // Bouton Move en mode sélection avec items
                        Menu {
                            ForEach(availableCategories, id: \.self) { category in
                                Button {
                                    hapticTrigger += 1
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
                                    .font(.system(size: 17))
                                    .foregroundColor(.primary)
                                    .padding(.bottom, 1)
                            }
                            .frame(height: 48)
                            .frame(minWidth: 48)
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(.regularMaterial)
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                        }
                        .menuStyle(.button)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.98)),
                            removal: .opacity.combined(with: .scale(scale: 0.98))
                        ))
                    }

                    Spacer()
                } else {
                    // Bouton Search normal
                    Button(action: openSearch) {
                        if searchQuery.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: scrollProgress > 0.5 ? 20 : 18, weight: .medium))
                                    .foregroundColor(scrollProgress > 0.5 ? .primary : .primary.opacity(0.4))

                                if scrollProgress < 0.5 {
                                    Text("Search")
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(.primary.opacity(0.4))
                                        .opacity(CGFloat(1 - (scrollProgress * 2)))
                                    Spacer()
                                }
                            }
                            .frame(height: scrollProgress > 0.5 ? 54 : 48)
                            .padding(.horizontal, scrollProgress > 0.5 ? 0 : CGFloat(24 - (24 * scrollProgress * 2)))
                            .frame(maxWidth: scrollProgress > 0.5 ? 54 : .infinity)
                            .contentTransition(.opacity)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.98)),
                                removal: .opacity.combined(with: .scale(scale: 0.98))
                            ))
                            .background(
                                Group {
                                    if scrollProgress > 0.5 {
                                        Circle()
                                            .fill(.regularMaterial)
                                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                            .matchedGeometryEffect(id: "searchBackground", in: searchTransitionNS)
                                    } else {
                                        RoundedRectangle(cornerRadius: 28)
                                            .fill(.regularMaterial)
                                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                            .matchedGeometryEffect(id: "searchBackground", in: searchTransitionNS)
                                    }
                                }
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
                            .frame(maxWidth: .infinity)
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
                    .frame(maxWidth: searchQuery.isEmpty && scrollProgress > 0.5 ? 54 : .infinity)
                }
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
                                .fill(.regularMaterial)
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        }
                    }
                )
            }
            .opacity(isSelectionMode ? 1 : (scrollProgress > 0.5 ? 0 : CGFloat(1 - (scrollProgress * 2))))
            } // end if !isMenuOpen
        }
        .padding(.horizontal, 28)
    }

    // MARK: - Actions
    private func dismissSearch() {
        withAnimation(unifiedAnimation) {
            showSearchBar = false
            isSearchFocused = false
            isAnimatingSearchOpen = false
        }
    }
    
    private func openSearch() {
        hapticTrigger += 1
        onRestoreBar()
        isAnimatingSearchOpen = true
        withAnimation(unifiedAnimation) {
            showSearchBar = true
        }
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
            .background(
                Circle()
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
    }
}

