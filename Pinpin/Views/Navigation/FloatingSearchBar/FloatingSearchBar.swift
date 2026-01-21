import SwiftUI

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
    private let searchTransitionAnimation = Animation.smooth(duration: 0.35)
    
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
                    withAnimation(searchTransitionAnimation.delay(0.08)) {
                        showCapsules = true
                    }
                    withAnimation(searchTransitionAnimation.delay(0.12)) {
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
        .animation(searchTransitionAnimation, value: showSearchBar)
        .animation(searchTransitionAnimation, value: isAnimatingSearchOpen)
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
        withAnimation(searchTransitionAnimation) {
            showSearchBar = false
            isSearchFocused = false
            isAnimatingSearchOpen = false
        }
    }

    private func openSearch() {
        triggerHaptic()
        onRestoreBar()
        isAnimatingSearchOpen = true
        withAnimation(searchTransitionAnimation) {
            showSearchBar = true
        }
    }
    
    private func triggerHaptic() {
        hapticTrigger += 1
    }
}

