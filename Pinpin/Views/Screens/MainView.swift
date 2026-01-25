//
//  MainView.swift
//  Pinpin
//
//  Vue principale de l'application
import SwiftUI
import SwiftData

// Structure pour passer les données au TextEditSheet via .sheet(item:)
struct TextEditContext: Identifiable {
    let id = UUID()
    let item: ContentItem?
    let targetCategory: Category?
}

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = MainViewModel()
    @Namespace private var heroNamespace

    @Query(sort: \Category.sortOrder, order: .forward)
    private var allCategories: [Category]
    
    @State private var storageStatsRefreshTrigger = 0
    @State private var isMenuOpen = false
    @State private var menuSwipeProgress: CGFloat = 0
    @State private var isMenuDragging = false
    @State private var showFloatingBar: Bool = true
    @AppStorage("numberOfColumns") private var numberOfColumns: Int = AppConstants.defaultColumns
    @State private var hapticTrigger: Int = 0

    // Confirmation de suppression individuelle
    @State private var showDeleteConfirmation: Bool = false
    @State private var itemToDelete: ContentItem?

    // TextEditSheet state - utilise une struct pour garantir le passage correct des données
    @State private var textEditContext: TextEditContext?
    
    // Navigation pour ItemDetailView
    @State private var selectedItem: ContentItem?
    
    // État d'édition des catégories (synchronisé avec CategoryManager via notification)
    @State private var isEditingCategories: Bool = false

    // Propriétés calculées pour l'espacement et le corner radius
    private var dynamicSpacing: CGFloat {
        AppConstants.spacing(for: numberOfColumns)
    }

    private var dynamicCornerRadius: CGFloat {
        AppConstants.cornerRadius(for: numberOfColumns, disabled: false)
    }
    

    // SwiftData Query
    @Query(sort: \ContentItem.createdAt, order: .reverse)
    private var allContentItems: [ContentItem]

    // Items filtrés via ViewModel (cached dans le ViewModel)
    private var filteredItems: [ContentItem] {
        viewModel.filteredItems(from: allContentItems)
    }

    init() {
    }

    var body: some View {
        GeometryReader { geometry in
            mainDrawerContent(geometry: geometry)
                .overlay(alignment: .bottom) {
                    floatingSearchBarView(screenWidth: geometry.size.width)
                }
        }
        .sheet(item: $selectedItem) { item in
                ItemDetailView(item: item, namespace: heroNamespace)
                    .navigationTransition(.zoom(sourceID: item.id, in: heroNamespace))
                    .presentationDragIndicator(.hidden)
            }
            .sensoryFeedback(.selection, trigger: hapticTrigger)
            .sheet(item: $textEditContext) { context in
                TextEditSheet(item: context.item, targetCategory: context.targetCategory)
            }
            .alert("Confirm Deletion", isPresented: $showDeleteConfirmation) {
                deleteConfirmationButtons
            } message: {
                Text("Are you sure you want to delete this item? This action cannot be undone.")
            }
            .onAppear {
                // S'assurer que le nombre de colonnes est valide (fix pour legacy config)
                if numberOfColumns < AppConstants.minColumns {
                    numberOfColumns = AppConstants.minColumns
                } else if numberOfColumns > AppConstants.maxColumns {
                    numberOfColumns = AppConstants.maxColumns
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FilterMenuViewRequestToggleEditCategories"))) { _ in
                withAnimation(.spring(duration: 0.3)) {
                    isEditingCategories.toggle()
                }
            }
            .onChange(of: isMenuOpen) { _, isOpen in
                // Quitter le mode édition quand on ferme le menu
                if !isOpen && isEditingCategories {
                    withAnimation(.spring(duration: 0.3)) {
                        isEditingCategories = false
                    }
                }
            }
    }
    
    // MARK: - Main Drawer View
    private func mainDrawerContent(geometry: GeometryProxy) -> some View {
        let drawerWidth = AppConstants.drawerWidth(
            for: geometry.size.width,
            screenHeight: geometry.size.height
        )

        return PushingSideDrawer(
            isOpen: $isMenuOpen,
            swipeProgress: $menuSwipeProgress,
            isDragging: $isMenuDragging,
            width: drawerWidth,
            isSwipeDisabled: viewModel.showSearchBar,
            isEditingMode: isEditingCategories
        ) {
            mainContentView
        } drawer: {
            FilterMenuView(
                selectedContentType: $viewModel.selectedContentType,
                isMenuOpen: $isMenuOpen,
                isEditingCategories: $isEditingCategories,
                isMenuDragging: isMenuDragging
            )
        }
    }
    
    // MARK: - Main Content View
    private var mainContentView: some View {
        ZStack {
            Color(.systemBackground)

            MainContentScrollView(
                selectedContentType: $viewModel.selectedContentType,
                searchQuery: $viewModel.searchQuery,
                isMenuOpen: $isMenuOpen,
                numberOfColumns: $numberOfColumns,
                scrollProgress: $viewModel.scrollProgress,
                hapticTrigger: $hapticTrigger,
                filteredItems: filteredItems,
                dynamicSpacing: dynamicSpacing,
                dynamicCornerRadius: dynamicCornerRadius,
                isSelectionMode: viewModel.isSelectionMode,
                selectedItems: viewModel.selectedItems,
                storageStatsRefreshTrigger: storageStatsRefreshTrigger,
                minColumns: AppConstants.minColumns,
                maxColumns: AppConstants.maxColumns,
                onCategoryChange: handleCategoryChange,
                onSearchQueryChange: handleSearchQueryChange,
                onMenuStateChange: handleMenuStateChange,
                onToggleSelection: { uuid in
                    viewModel.toggleItemSelection(uuid)
                },
                onDeleteItem: { item in
                    itemToDelete = item
                    showDeleteConfirmation = true
                },
                onStorageStatsRefresh: {
                    storageStatsRefreshTrigger += 1
                },
                onItemTap: { item in
                    selectedItem = item
                },
                heroNamespace: heroNamespace
            )

            if viewModel.showSearchBar {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .animation(.smooth(duration: 0.35), value: viewModel.showSearchBar)
                    .onTapGesture {
                        viewModel.closeSearch()
                    }
                    .gesture(
                        DragGesture(minimumDistance: 30)
                            .onEnded { value in
                                if value.translation.height > 50 {
                                    viewModel.closeSearch()
                                }
                            }
                    )
            }
        }
    }
    

    
    // MARK: - Floating Search Bar
    @ViewBuilder
    private func floatingSearchBarView(screenWidth: CGFloat) -> some View {
        if showFloatingBar {
            FloatingSearchBar(
                searchQuery: $viewModel.searchQuery,
                showSearchBar: $viewModel.showSearchBar,
                isSelectionMode: $viewModel.isSelectionMode,
                selectedItems: $viewModel.selectedItems,
                isMenuOpen: $isMenuOpen,
                menuSwipeProgress: menuSwipeProgress,
                scrollProgress: viewModel.scrollProgress,
                selectedContentType: viewModel.selectedContentType,
                totalPinsCount: filteredItems.count,
                bottomPadding: 0,
                availableCategories: allCategories.map { $0.name },
                currentCategory: viewModel.selectedContentType,
                isEditingCategories: isEditingCategories,
                screenWidth: screenWidth,
                onSelectAll: {
                    viewModel.selectAll(from: filteredItems)
                },
                onDeleteSelected: {
                    deleteSelectedItems(from: filteredItems)
                    storageStatsRefreshTrigger += 1
                },
                onRestoreBar: {
                    viewModel.scrollProgress = 0.0
                },
                onMoveToCategory: { categoryName in
                    moveSelectedItemsToCategory(categoryName, from: filteredItems)
                },
                onCreateNote: {
                    createNewTextNote()
                }
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    // MARK: - Delete Confirmation Buttons
    @ViewBuilder
    private var deleteConfirmationButtons: some View {
        Button("Cancel", role: .cancel) {
            itemToDelete = nil
        }
        Button("Delete", role: .destructive) {
            if let item = itemToDelete {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    modelContext.delete(item)
                    try? modelContext.save()
                    storageStatsRefreshTrigger += 1
                }
            }
            itemToDelete = nil
        }
    }
    
}



// MARK: - Helpers
private extension MainView {
    func handleCategoryChange() {
        viewModel.scrollProgress = 0.0
    }
    
    func handleSearchQueryChange(_ newValue: String) {
        // Scroll géré par MainContentScrollView via scrollPosition
    }
    
    func handleMenuStateChange(isOpen: Bool) {
        if isOpen {
            viewModel.closeSearch()
        } else {
            withAnimation(.spring) {
                viewModel.scrollProgress = 0.0
            }
        }
    }
    

    func moveSelectedItemsToCategory(_ categoryName: String, from items: [ContentItem]) {
        hapticTrigger += 1
        
        let itemsToMove = items.filter { viewModel.selectedItems.contains($0.safeId) }
        guard let targetCategory = allCategories.first(where: { $0.name == categoryName }) else { return }

        for item in itemsToMove {
            item.category = targetCategory
        }
        try? modelContext.save()
        
        // Invalider le cache pour forcer le rafraîchissement de la vue
        viewModel.invalidateCache()

        viewModel.selectedItems.removeAll()
        viewModel.isSelectionMode = false
    }

    func createNewTextNote() {
        // Déterminer la catégorie cible
        let targetCategory: Category?
        
        if let selectedType = viewModel.selectedContentType,
           let category = allCategories.first(where: { $0.name == selectedType }) {
            // On est dans une catégorie spécifique → utiliser cette catégorie
            targetCategory = category
        } else {
            // On est sur "All" ou catégorie non trouvée → utiliser Misc
            if let misc = allCategories.first(where: { $0.name == "Misc" }) {
                targetCategory = misc
            } else {
                // Créer Misc si elle n'existe pas
                let maxSortOrder = allCategories.map { $0.sortOrder }.max() ?? -1
                let misc = Category(name: "Misc", sortOrder: maxSortOrder + 1)
                modelContext.insert(misc)
                try? modelContext.save()
                targetCategory = misc
            }
        }
        
        // Créer le contexte et ouvrir le sheet
        textEditContext = TextEditContext(item: nil, targetCategory: targetCategory)
    }
    
    func deleteSelectedItems(from items: [ContentItem]) {
        let itemsToDelete = items.filter { viewModel.selectedItems.contains($0.safeId) }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            for item in itemsToDelete {
                modelContext.delete(item)
            }
            try? modelContext.save()
            viewModel.selectedItems.removeAll()
            viewModel.isSelectionMode = false
        }
    }
}

