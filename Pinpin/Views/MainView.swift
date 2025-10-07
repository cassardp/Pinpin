//
//  MainView.swift
//  Pinpin
//
//  Vue principale de l'application
import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var dataService = DataService.shared
    private let userPreferences = UserPreferences.shared
    @StateObject private var viewModel = MainViewModel()
    @StateObject private var syncService: SwiftDataSyncService

    @Query(sort: \Category.sortOrder, order: .forward)
    private var allCategories: [Category]
    
    @State private var storageStatsRefreshTrigger = 0
    @State private var isMenuOpen = false
    @State private var menuSwipeProgress: CGFloat = 0
    @State private var isMenuDragging = false
    @State private var isSettingsOpen = false
    @State private var settingsDetent: PresentationDetent = .medium
    @State private var isInfoOpen = false
    @State private var showFloatingBar: Bool = true
    @AppStorage("numberOfColumns") private var numberOfColumns: Int = AppConstants.defaultColumns
    @State private var hapticTrigger: Int = 0

    // Confirmation de suppression individuelle
    @State private var showDeleteConfirmation: Bool = false
    @State private var itemToDelete: ContentItem?

    // TextEditSheet state
    @State private var showTextEditSheet: Bool = false
    @State private var textEditItem: ContentItem?
    @State private var textEditTargetCategory: Category?

    // Propriétés calculées pour l'espacement et le corner radius
    private var dynamicSpacing: CGFloat {
        AppConstants.spacing(for: numberOfColumns)
    }

    private var dynamicCornerRadius: CGFloat {
        AppConstants.cornerRadius(for: numberOfColumns, disabled: userPreferences.disableCornerRadius)
    }
    

    // SwiftData Query
    @Query(sort: \ContentItem.createdAt, order: .reverse)
    private var allContentItems: [ContentItem]

    // Items filtrés via ViewModel
    private var filteredItems: [ContentItem] {
        viewModel.filteredItems(from: allContentItems)
    }
    
    // Total avant pagination
    private var totalItemsCount: Int {
        viewModel.totalItemsCount(from: allContentItems)
    }

    init() {
        let dataService = DataService.shared
        self._dataService = StateObject(wrappedValue: dataService)
        
        // Initialiser le service de sync avec le contexte
        let context = dataService.container.mainContext
        self._syncService = StateObject(wrappedValue: SwiftDataSyncService(modelContext: context))
    }

    var body: some View {
        mainDrawerView
            .overlay(alignment: .bottom) {
                floatingSearchBarView
            }
            .task {
                syncService.startListening()
            }
            .onDisappear {
                syncService.stopListening()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                syncService.forceRefresh()
            }
            .sensoryFeedback(.selection, trigger: hapticTrigger)
            .sheet(isPresented: $isSettingsOpen) {
                settingsSheet
            }
            .sheet(isPresented: $isInfoOpen) {
                InfoSheet()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
            .sheet(isPresented: $showTextEditSheet) {
                TextEditSheet(item: textEditItem, targetCategory: textEditTargetCategory)
                    .onDisappear {
                        textEditItem = nil
                        textEditTargetCategory = nil
                    }
            }
            .alert("Confirm Deletion", isPresented: $showDeleteConfirmation) {
                deleteConfirmationButtons
            } message: {
                Text("Are you sure you want to delete this item? This action cannot be undone.")
            }
    }
    
    // MARK: - Main Drawer View
    private var mainDrawerView: some View {
        GeometryReader { geometry in
            PushingSideDrawer(
                isOpen: $isMenuOpen,
                swipeProgress: $menuSwipeProgress,
                isDragging: $isMenuDragging,
                width: geometry.size.width * 0.8,
                isSwipeDisabled: viewModel.showSearchBar
            ) {
                mainContentView
            } drawer: {
                FilterMenuView(
                    selectedContentType: $viewModel.selectedContentType,
                    isMenuOpen: $isMenuOpen,
                    isMenuDragging: isMenuDragging,
                    onOpenAbout: { },
                    onOpenSettings: { isSettingsOpen = true }
                )
            }
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
                isSettingsOpen: $isSettingsOpen,
                numberOfColumns: $numberOfColumns,
                scrollProgress: $viewModel.scrollProgress,
                hapticTrigger: $hapticTrigger,
                filteredItems: filteredItems,
                totalItemsCount: totalItemsCount,
                displayLimit: viewModel.displayLimit,
                dynamicSpacing: dynamicSpacing,
                dynamicCornerRadius: dynamicCornerRadius,
                isSelectionMode: viewModel.isSelectionMode,
                selectedItems: viewModel.selectedItems,
                syncServiceLastSaveDate: syncService.lastSaveDate,
                storageStatsRefreshTrigger: storageStatsRefreshTrigger,
                dataService: dataService,
                minColumns: AppConstants.minColumns,
                maxColumns: AppConstants.maxColumns,
                onCategoryChange: handleCategoryChange,
                onSearchQueryChange: handleSearchQueryChange,
                onMenuStateChange: handleMenuStateChange,
                onLoadMore: { index in
                    viewModel.loadMoreIfNeeded(
                        currentIndex: index,
                        totalItems: filteredItems.count,
                        totalBeforePagination: totalItemsCount
                    )
                },
                onToggleSelection: { uuid in
                    viewModel.toggleItemSelection(uuid)
                },
                onDeleteItem: { item in
                    itemToDelete = item
                    showDeleteConfirmation = true
                },
                onStorageStatsRefresh: {
                    storageStatsRefreshTrigger += 1
                }
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
    
    // MARK: - Settings Sheet
    private var settingsSheet: some View {
        SettingsView()
            .presentationDetents([.medium, .large], selection: $settingsDetent)
            .presentationDragIndicator(.hidden)
    }
    
    // MARK: - Floating Search Bar
    @ViewBuilder
    private var floatingSearchBarView: some View {
        if showFloatingBar {
            FloatingSearchBar(
                searchQuery: $viewModel.searchQuery,
                showSearchBar: $viewModel.showSearchBar,
                isSelectionMode: $viewModel.isSelectionMode,
                selectedItems: $viewModel.selectedItems,
                showSettings: $isSettingsOpen,
                showInfo: $isInfoOpen,
                isMenuOpen: $isMenuOpen,
                menuSwipeProgress: menuSwipeProgress,
                scrollProgress: viewModel.scrollProgress,
                selectedContentType: viewModel.selectedContentType,
                totalPinsCount: filteredItems.count,
                bottomPadding: 0,
                availableCategories: allCategories.map { $0.name },
                currentCategory: viewModel.selectedContentType,
                onSelectAll: {
                    viewModel.selectAll(from: filteredItems)
                },
                onDeleteSelected: {
                    viewModel.deleteSelectedItems(from: filteredItems)
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
                withAnimation(.bouncy(duration: 0.5)) {
                    dataService.deleteContentItem(item)
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

        ContentItemRepository(context: modelContext).updateCategories(itemsToMove, category: targetCategory)
        try? modelContext.save()

        viewModel.selectedItems.removeAll()
        viewModel.isSelectionMode = false
    }

    func createNewTextNote() {
        textEditItem = nil
        textEditTargetCategory = if let selectedType = viewModel.selectedContentType {
            allCategories.first { $0.name == selectedType }
        } else {
            try? CategoryRepository(context: modelContext).findOrCreateMiscCategory()
        }
        showTextEditSheet = true
    }
}

