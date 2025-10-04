//
//  MainView.swift
//  Pinpin
//
//  Vue principale de l'application
//

import SwiftUI
import SwiftData
import UserNotifications
import UIKit

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var dataService = DataService.shared
    @StateObject private var userPreferences = UserPreferences.shared
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
    @State private var scrollOffset: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    @AppStorage("numberOfColumns") private var numberOfColumns: Int = AppConstants.defaultColumns
    @State private var hapticTrigger: Int = 0

    // Bornes de colonnes
    private let minColumns: Int = AppConstants.minColumns
    private let maxColumns: Int = AppConstants.maxColumns

    // Confirmation de suppression individuelle
    @State private var showDeleteConfirmation: Bool = false
    @State private var itemToDelete: ContentItem?

    // Hauteur du clavier pour ajuster la barre flottante
    @State private var keyboardHeight: CGFloat = 0
    
    // Timer pour masquer la barre automatiquement
    @State private var hideBarTimer: Timer?

    // TextEditSheet state
    @State private var showTextEditSheet: Bool = false
    @State private var textEditItem: ContentItem?

    // Propriétés calculées pour l'espacement et le corner radius
    private var dynamicSpacing: CGFloat {
        switch numberOfColumns {
        case 1: return 16
        case 2: return 10
        case 3: return 8
        case 4: return 6
        default: return 10
        }
    }

    private var dynamicCornerRadius: CGFloat {
        if userPreferences.disableCornerRadius { return 0 }
        switch numberOfColumns {
        case 1: return 20
        case 2: return 14
        case 3: return 10
        case 4: return 8
        default: return 14
        }
    }
    
    // Écran courant via la fenêtre active (évite UIScreen.main déprécié)
    private var keyWindowScene: UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
    }

    private var screenBounds: CGRect {
        if let scene = keyWindowScene {
            return scene.screen.bounds
        }
        // Fallback si aucune scène active (ex: previews) — éviter UIScreen.main déprécié
        if let anyScene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            return anyScene.screen.bounds
        }
        // Dernier recours : utiliser les sessions ouvertes pour trouver un écran
        if let session = UIApplication.shared.openSessions.first,
           let windowScene = session.scene as? UIWindowScene {
            return windowScene.screen.bounds
        }
        // Fallback final avec des dimensions par défaut
        return CGRect(x: 0, y: 0, width: 390, height: 844)
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
            .onAppear(perform: handleViewAppear)
            .onDisappear(perform: handleViewDisappear)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                syncService.forceRefresh()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
                handleKeyboardNotification(notification)
            }
            .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
            .sheet(isPresented: $isSettingsOpen) {
                settingsSheet
            }
            .sheet(isPresented: $isInfoOpen) {
                InfoSheet()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
            .sheet(isPresented: $showTextEditSheet) {
                if let item = textEditItem {
                    TextEditSheet(item: item)
                        .onDisappear {
                            // Si le titre est vide après la fermeture, supprimer l'item
                            if item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                modelContext.delete(item)
                                try? modelContext.save()
                            }
                            textEditItem = nil
                        }
                }
            }
            .safeAreaInset(edge: .bottom) {
                floatingSearchBarView
            }
            .alert("Confirm Deletion", isPresented: $showDeleteConfirmation) {
                deleteConfirmationButtons
            } message: {
                Text("Are you sure you want to delete this item? This action cannot be undone.")
            }
    }
    
    // MARK: - Main Drawer View
    private var mainDrawerView: some View {
        PushingSideDrawer(
            isOpen: $isMenuOpen,
            swipeProgress: $menuSwipeProgress,
            isDragging: $isMenuDragging,
            width: screenBounds.width * 0.8,
            isSwipeDisabled: viewModel.showSearchBar
        ) {
            mainContentView
        } drawer: {
            drawerMenuView
        }
    }
    
    // MARK: - Main Content View
    private var mainContentView: some View {
        ZStack {
            Color(UIColor.systemBackground)
            
            topRestoreBar
            
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
                screenBounds: screenBounds,
                syncServiceLastSaveDate: syncService.lastSaveDate,
                storageStatsRefreshTrigger: storageStatsRefreshTrigger,
                dataService: dataService,
                minColumns: minColumns,
                maxColumns: maxColumns,
                onCategoryChange: handleCategoryChange,
                onSearchQueryChange: handleSearchQueryChange,
                onMenuStateChange: handleMenuStateChange,
                onRefresh: refreshContentAsync,
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
            
            searchBarOverlay
        }
    }
    
    // MARK: - Top Restore Bar
    @ViewBuilder
    private var topRestoreBar: some View {
        if viewModel.scrollProgress > 0.5 {
            VStack {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 60)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            viewModel.scrollProgress = 0.0
                        }
                    }
                Spacer()
            }
            .ignoresSafeArea(edges: .top)
        }
    }
    
    // MARK: - Search Bar Overlay
    @ViewBuilder
    private var searchBarOverlay: some View {
        if viewModel.showSearchBar {
            Color.black.opacity(0.001)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissKeyboard()
                    viewModel.closeSearch()
                }
        }
    }
    
    // MARK: - Drawer Menu
    private var drawerMenuView: some View {
        FilterMenuView(
            selectedContentType: $viewModel.selectedContentType,
            isMenuOpen: $isMenuOpen,
            isMenuDragging: isMenuDragging,
            onOpenAbout: { },
            onOpenSettings: {
                isSettingsOpen = true
            }
        )
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
                bottomPadding: keyboardHeight > 0 ? -4 : 0,
                availableCategories: allCategories.map { $0.name },
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
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .bottom)),
                removal: .opacity.combined(with: .move(edge: .bottom))
            ))
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
                withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                    dataService.deleteContentItem(item)
                    storageStatsRefreshTrigger += 1
                }
            }
            itemToDelete = nil
        }
    }
    
    // MARK: - Lifecycle Handlers
    private func handleViewAppear() {
        viewModel.clearSearch()
        viewModel.closeSearch()
        refreshContent()
        syncService.startListening()
    }
    
    private func handleViewDisappear() {
        syncService.stopListening()
    }

}



// MARK: - Helpers
private extension MainView {
    func handleCategoryChange(using proxy: ScrollViewProxy) {
        withTransaction(Transaction(animation: nil)) {
            proxy.scrollTo("top", anchor: .top)
        }
        viewModel.scrollProgress = 0.0
    }
    
    func handleSearchQueryChange(_ newValue: String, using proxy: ScrollViewProxy) {
        if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            withTransaction(Transaction(animation: nil)) {
                proxy.scrollTo("top", anchor: .top)
            }
        }
    }
    
    func handleMenuStateChange(isOpen: Bool) {
        if isOpen {
            viewModel.closeSearch()
            dismissKeyboard()
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                viewModel.scrollProgress = 0.0
            }
        }
    }
    
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func handleKeyboardNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        let screenHeight = screenBounds.height
        let newHeight = max(0, screenHeight - endFrame.origin.y)
        withAnimation(.easeOut(duration: duration)) {
            keyboardHeight = newHeight
        }
    }
    
    func refreshContent() {
        // Vider le cache pour forcer la lecture depuis le disque
        modelContext.rollback()
        
        // SwiftData + CloudKit synchronisent automatiquement
        _ = dataService.loadContentItems()
        print("[MainView] 🔄 Content refreshed")
    }
    
    func refreshContentAsync() async {
        print("[MainView] 🔄 Pull-to-refresh démarré...")

        await MainActor.run {
            // Vider le cache SwiftData pour forcer la lecture depuis le disque
            modelContext.rollback()
        }

        // Petit délai pour laisser CloudKit synchroniser
        try? await Task.sleep(for: .milliseconds(500))

        await MainActor.run {
            // Forcer le refresh du SwiftDataSyncService
            syncService.forceRefresh()

            // Recharger les données
            _ = dataService.loadContentItems()

            print("[MainView] ✅ Pull-to-refresh terminé!")
        }
    }

    func moveSelectedItemsToCategory(_ categoryName: String, from items: [ContentItem]) {
        hapticTrigger += 1

        let itemsToMove = items.filter { viewModel.selectedItems.contains($0.safeId) }
        let targetCategory = allCategories.first { $0.name == categoryName }

        // Utiliser le repository pour mettre à jour les catégories
        let contentRepo = ContentItemRepository(context: modelContext)
        contentRepo.updateCategories(itemsToMove, category: targetCategory)

        do {
            try modelContext.save()
        } catch {
            print("Failed to move items to category: \(error)")
        }

        viewModel.selectedItems.removeAll()
        viewModel.isSelectionMode = false
    }

    func createNewTextNote() {
        let categoryRepo = CategoryRepository(context: modelContext)

        // Déterminer la catégorie : si selectedContentType est nil (All), utiliser Misc
        // Sinon, utiliser la catégorie en cours
        let targetCategory: Category?
        if let selectedType = viewModel.selectedContentType {
            // Chercher la catégorie correspondante dans allCategories
            targetCategory = allCategories.first { $0.name == selectedType }
        } else {
            // On est dans "All", utiliser Misc
            targetCategory = try? categoryRepo.findOrCreateMiscCategory()
        }

        // Créer un nouvel item textonly vide avec la catégorie appropriée
        let newItem = ContentItem(
            title: "",
            itemDescription: nil,
            url: nil,
            thumbnailUrl: nil,
            imageData: nil,
            category: targetCategory
        )

        // L'ajouter au contexte
        modelContext.insert(newItem)

        // Définir l'item à éditer et afficher le sheet
        textEditItem = newItem
        showTextEditSheet = true
    }
}

