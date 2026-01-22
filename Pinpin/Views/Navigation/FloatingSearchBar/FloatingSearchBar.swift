import SwiftUI

private let searchAnimation = Animation.smooth(duration: 0.35)

// MARK: - FloatingSearchBar
struct FloatingSearchBar: View {
    // MARK: - Bindings
    @Binding var searchQuery: String
    @Binding var showSearchBar: Bool
    @Binding var isSelectionMode: Bool
    @Binding var selectedItems: Set<UUID>
    @Binding var isMenuOpen: Bool
    
    // MARK: - Properties
    var menuSwipeProgress: CGFloat
    var scrollProgress: CGFloat
    var selectedContentType: String?
    var totalPinsCount: Int = 0
    var bottomPadding: CGFloat = 12
    var availableCategories: [String] = []
    var currentCategory: String?
    var isEditingCategories: Bool = false

    // MARK: - Actions
    let onSelectAll: () -> Void
    let onDeleteSelected: () -> Void
    let onRestoreBar: () -> Void
    let onMoveToCategory: (String) -> Void
    let onCreateNote: () -> Void
    
    // MARK: - State
    @FocusState private var isSearchFocused: Bool
    @Namespace private var searchTransitionNS
    @State private var isAnimatingSearchOpen: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var hapticTrigger: Int = 0
    @State private var showCapsules: Bool = false
    @State private var showCloseButton: Bool = false
    
    // MARK: - Constants
    private let scrollAnimation = Animation.smooth(duration: 0.3)
    
    private enum NotificationName {
        static let createCategory = Notification.Name("FilterMenuViewRequestCreateCategory")
    }

    var body: some View {
        // Seulement la barre de recherche/contrôles pour safeAreaInset
        ZStack {
            if showSearchBar {
                SearchBarView(
                    searchQuery: $searchQuery,
                    showSearchBar: $showSearchBar,
                    isSearchFocused: $isSearchFocused,
                    selectedContentType: selectedContentType,
                    showCapsules: showCapsules,
                    showCloseButton: showCloseButton,
                    searchTransitionNS: searchTransitionNS,
                    onDismiss: dismissSearch,
                    onHaptic: triggerHaptic
                )
                .transition(.identity)
                .onAppear {
                    // Petit délai pour garantir que le clavier s'affiche
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        isSearchFocused = true
                    }
                    // Apparition progressive des capsules et du bouton close avec timing optimisé
                    withAnimation(searchAnimation.delay(0.08)) {
                        showCapsules = true
                    }
                    withAnimation(searchAnimation.delay(0.12)) {
                        showCloseButton = true
                    }
                    isAnimatingSearchOpen = false
                }
                .onDisappear {
                    showCapsules = false
                    showCloseButton = false
                }
            } else {
                SearchControlsRow(
                    searchQuery: $searchQuery,
                    isSelectionMode: $isSelectionMode,
                    selectedItems: $selectedItems,
                    showDeleteConfirmation: $showDeleteConfirmation,
                    isMenuOpen: $isMenuOpen,
                    isAnimatingSearchOpen: $isAnimatingSearchOpen,
                    scrollProgress: scrollProgress,
                    availableCategories: availableCategories,
                    currentCategory: currentCategory,
                    searchTransitionNS: searchTransitionNS,
                    isEditingCategories: isEditingCategories,
                    onSelectAll: onSelectAll,
                    onMoveToCategory: onMoveToCategory,
                    onRestoreBar: onRestoreBar,
                    onCreateNote: onCreateNote,
                    onOpenSearch: openSearch,
                    onHaptic: triggerHaptic
                )
                .transition(.scale(scale: 0.96).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, bottomPadding)
        .background(
            VStack(spacing: 0) {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: .black.opacity(0.02), location: 0.4),
                        .init(color: .black.opacity(0.06), location: 0.6),
                        .init(color: .black.opacity(0.12), location: 0.75),
                        .init(color: .black.opacity(0.22), location: 0.9),
                        .init(color: .black.opacity(0.35), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity)
            .ignoresSafeArea()
        )
        .animation(searchAnimation, value: showSearchBar)
        .animation(searchAnimation, value: isAnimatingSearchOpen)
        .animation(scrollAnimation, value: scrollProgress)
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
        .alert("Confirm Deletion", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive, action: onDeleteSelected)
        } message: {
            Text(deleteConfirmationMessage)
        }
        .onReceive(NotificationCenter.default.publisher(for: NotificationName.createCategory)) { _ in
            // Notification reçue quand on crée une catégorie
        }
    }
    
    // MARK: - Computed Properties
    private var deleteConfirmationMessage: String {
        "Are you sure you want to delete \(selectedItems.count) item\(selectedItems.count > 1 ? "s" : "")? This action cannot be undone."
    }

    // MARK: - Actions
    private func dismissSearch() {
        withAnimation(searchAnimation) {
            showSearchBar = false
            isSearchFocused = false
            isAnimatingSearchOpen = false
        }
    }

    private func openSearch() {
        triggerHaptic()
        onRestoreBar()
        isAnimatingSearchOpen = true
        withAnimation(searchAnimation) {
            showSearchBar = true
        }
    }
    
    private func triggerHaptic() {
        hapticTrigger += 1
    }
}

// MARK: - SearchBarView
struct SearchBarView: View {
    // MARK: - Bindings
    @Binding var searchQuery: String
    @Binding var showSearchBar: Bool
    @FocusState.Binding var isSearchFocused: Bool
    
    // MARK: - Properties
    var selectedContentType: String?
    var showCapsules: Bool
    var showCloseButton: Bool
    var searchTransitionNS: Namespace.ID
    
    // MARK: - Actions
    let onDismiss: () -> Void
    let onHaptic: () -> Void
    
    // MARK: - Computed Properties
    private var placeholderText: String {
        if let selectedType = selectedContentType {
            return "Search in \(selectedType.capitalized)..."
        }
        return "Search..."
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Capsules de recherche prédéfinies (sans padding horizontal)
            if showCapsules {
                PredefinedSearchView(
                    searchQuery: $searchQuery,
                    selectedContentType: selectedContentType,
                    onSearchSelected: onDismiss
                )
                .transition(
                    .asymmetric(
                        insertion: .scale(scale: 0.92, anchor: .top).combined(with: .opacity).combined(with: .move(edge: .top)),
                        removal: .scale(scale: 0.95, anchor: .top).combined(with: .opacity)
                    )
                )
            }
            
            // Barre de recherche principale (avec padding horizontal)
            HStack(spacing: 8) {
                HStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                        .matchedGeometryEffect(id: "searchIcon", in: searchTransitionNS)
                    
                    ZStack(alignment: .leading) {
                        if searchQuery.isEmpty {
                            Text(placeholderText)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.primary.opacity(0.4))
                                .opacity(showSearchBar ? 1 : 0)
                                .animation(searchAnimation.delay(0.1), value: showSearchBar)
                        }
                        TextField("", text: $searchQuery)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.primary)
                            .opacity(showSearchBar ? 1 : 0)
                            .animation(searchAnimation.delay(0.1), value: showSearchBar)
                    }
                    .focused($isSearchFocused)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .submitLabel(.search)
                    .onSubmit { onDismiss() }
                    
                    if !searchQuery.isEmpty {
                        Button {
                            onHaptic()
                            searchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(height: 48)
                .padding(.horizontal, 18)
                .glassEffect()
                .glassEffectID("searchBackground", in: searchTransitionNS)
                
                // Bouton xmark pour fermer le clavier
                if showCloseButton {
                    Button {
                        onHaptic()
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 48, height: 48)
                            .floatingButtonBackground()
                    }
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.7).combined(with: .opacity),
                            removal: .scale(scale: 0.9).combined(with: .opacity)
                        )
                    )
                }
            }
            .padding(.bottom, 12)
            .padding(.horizontal, 12) // Padding pour la barre de recherche seulement
        }
    }
}

// MARK: - Shared Styles
extension View {
    func floatingButtonBackground(isHighlighted: Bool = false, cornerRadius: CGFloat = 24) -> some View {
        Group {
            if isHighlighted {
                self.glassEffect(.regular.tint(.red))
            } else {
                self.glassEffect()
            }
        }
    }
}

