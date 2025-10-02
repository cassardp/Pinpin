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
    
    @State private var storageStatsRefreshTrigger = 0
    @State private var isMenuOpen = false
    @State private var menuSwipeProgress: CGFloat = 0
    @State private var isMenuDragging = false
    @State private var isSettingsOpen = false
    @State private var settingsDetent: PresentationDetent = .medium
    @State private var showFloatingBar: Bool = true
    @State private var scrollOffset: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    @AppStorage("numberOfColumns") private var numberOfColumns: Int = AppConstants.defaultColumns

    // Bornes de colonnes
    private let minColumns: Int = AppConstants.minColumns
    private let maxColumns: Int = AppConstants.maxColumns

    // État du pinch
    @State private var pinchScale: CGFloat = 1.0
    @State private var isPinching: Bool = false
    
    // Confirmation de suppression individuelle
    @State private var showDeleteConfirmation: Bool = false
    @State private var itemToDelete: ContentItem?

    // Hauteur du clavier pour ajuster la barre flottante
    @State private var keyboardHeight: CGFloat = 0
    
    // Timer pour masquer la barre automatiquement
    @State private var hideBarTimer: Timer?

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
        PushingSideDrawer(
            isOpen: $isMenuOpen,
            swipeProgress: $menuSwipeProgress,
            isDragging: $isMenuDragging,
            width: UIScreen.main.bounds.width * 0.8,
            isSwipeDisabled: viewModel.showSearchBar // Désactiver le swipe en mode recherche
        ) {
            // Contenu principal
            ZStack {
                Color(UIColor.systemBackground)
                
                // Zone invisible en haut pour réafficher la barre
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

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            Color.clear.frame(height: 0).id("top")

                            if filteredItems.isEmpty {
                                GeometryReader { geometry in
                                    EmptyStateView()
                                        .frame(width: geometry.size.width, height: geometry.size.height)
                                }
                                .frame(height: UIScreen.main.bounds.height - 150)
                            } else {
                                VStack(spacing: 0) {
                                    PinterestLayoutWrapper(numberOfColumns: numberOfColumns, itemSpacing: dynamicSpacing) {
                                        ForEach(filteredItems, id: \.safeId) { item in
                                            if let index = filteredItems.firstIndex(of: item) {
                                                buildContentCard(for: item, at: index, cornerRadius: dynamicCornerRadius)
                                                    .overlay(selectionOverlay(for: item))
                                                    .transition(.scale.combined(with: .opacity))
                                                    .onAppear {
                                                        viewModel.loadMoreIfNeeded(
                                                            currentIndex: index,
                                                            totalItems: filteredItems.count,
                                                            totalBeforePagination: totalItemsCount
                                                        )
                                                    }
                                            } else {
                                                buildContentCard(for: item, at: 0, cornerRadius: dynamicCornerRadius)
                                                    .transition(.scale.combined(with: .opacity))
                                            }
                                        }
                                    }
                                }
                                .id(viewModel.selectedContentType ?? "all")
                                .scaleEffect(isPinching ? pinchScale : 1.0, anchor: .center)
                                .animation(.linear(duration: 0.08), value: pinchScale)
                                .allowsHitTesting(!isPinching)
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.3), value: viewModel.selectedContentType)

                                if viewModel.displayLimit < totalItemsCount {
                                    HStack {
                                        Spacer()
                                        ProgressView().scaleEffect(0.8)
                                        Text("Loading...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                    .padding(.vertical, 20)
                                }

                                if !filteredItems.isEmpty {
                                    StorageStatsView(
                                        selectedContentType: viewModel.selectedContentType,
                                        filteredItems: filteredItems
                                    )
                                    .padding(.top, 50)
                                    .padding(.bottom, 30)
                                    .id(storageStatsRefreshTrigger)
                                }
                            }
                        }
                        .padding(.horizontal, 10)
                        .onChange(of: viewModel.selectedContentType) { _, _ in
                            handleCategoryChange(using: proxy)
                        }
                        .onChange(of: viewModel.searchQuery) { _, newValue in
                            handleSearchQueryChange(newValue, using: proxy)
                        }
                        .onChange(of: isMenuOpen) { _, newValue in
                            handleMenuStateChange(isOpen: newValue)
                        }
                        .animation(nil, value: viewModel.selectedContentType)
                        // Solution Apple : forcer le refresh avec .id() quand les données changent
                        .id(syncService.lastSaveDate)
                    }
                    .scrollIndicators(.hidden)
                    .refreshable {
                        await refreshContentAsync()
                    }
                    .scrollDisabled(isMenuOpen || isSettingsOpen)
                    .highPriorityGesture(pinchGesture)
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                let dy = value.translation.height
                                if dy < -30 { // Scroll vers le haut (masquer)
                                    viewModel.scrollProgress = 1.0
                                } else if dy > 30 { // Scroll vers le bas (afficher)
                                    viewModel.scrollProgress = 0.0
                                }
                            }
                            .onEnded { value in
                                let dy = value.translation.height
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    if dy < -50 { // Si scroll vers le haut assez fort, garder masqué
                                        viewModel.scrollProgress = 1.0
                                    } else if dy > 50 { // Si scroll vers le bas assez fort, afficher
                                        viewModel.scrollProgress = 0.0
                                    }
                                    // Sinon, garder l'état actuel
                                }
                            }
                    )
                }

                // ✅ Overlay pour fermer searchbar
                if viewModel.showSearchBar {
                    Color.black.opacity(0.001)
                        .ignoresSafeArea()
                        .onTapGesture {
                            dismissKeyboard()
                            viewModel.closeSearch()
                        }
                }
            }
            // Bouclier overlay pendant pinch
            .overlay(
                Group {
                    if isPinching {
                        Color.clear
                            .contentShape(Rectangle())
                            .highPriorityGesture(DragGesture(minimumDistance: 0))
                            .highPriorityGesture(TapGesture())
                            .allowsHitTesting(true)
                    }
                }
            )
        } drawer: {
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
        .onAppear {
            viewModel.clearSearch()
            viewModel.closeSearch()
            refreshContent()
            
            // Démarrer l'écoute des changements externes
            syncService.startListening()
        }
        .onDisappear {
            syncService.stopListening()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Force un refresh complet au retour en foreground
            // Important pour iOS 17 où la détection automatique peut être partielle
            syncService.forceRefresh()
        }
        // Note : Le refresh automatique est géré par .id(syncService.lastSaveDate) sur la grille
        // Suivi hauteur clavier pour remonter la searchbar au-dessus
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
            handleKeyboardNotification(notification)
        }
        .sheet(isPresented: $isSettingsOpen) {
            SettingsView()
                .presentationDetents([.medium, .large], selection: $settingsDetent)
                .presentationDragIndicator(.hidden)
        }
        .safeAreaInset(edge: .bottom) {
            if showFloatingBar {
                FloatingSearchBar(
                    searchQuery: $viewModel.searchQuery,
                    showSearchBar: $viewModel.showSearchBar,
                    isSelectionMode: $viewModel.isSelectionMode,
                    selectedItems: $viewModel.selectedItems,
                    showSettings: $isSettingsOpen,
                    menuSwipeProgress: menuSwipeProgress,
                    scrollProgress: viewModel.scrollProgress,
                    selectedContentType: viewModel.selectedContentType,
                    totalPinsCount: filteredItems.count,
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
                    onShareCategory: {
                        shareCurrentCategory()
                    },
                    bottomPadding: keyboardHeight > 0 ? 0 : 12
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                    removal: .opacity.combined(with: .move(edge: .bottom))
                ))
            }
        }
        .alert("Confirm Deletion", isPresented: $showDeleteConfirmation) {
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
        } message: {
            Text("Are you sure you want to delete this item? This action cannot be undone.")
        }
    }

    // MARK: - Sélection (déléguée au ViewModel)
    
    private func shareCurrentCategory() {
        let shareText = viewModel.shareCurrentCategory(items: filteredItems)
        
        let activityViewController = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            // Configuration pour iPad
            if let popover = activityViewController.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootViewController.present(activityViewController, animated: true)
        }
    }

    // MARK: - Card
    @ViewBuilder
    private func buildContentCard(for item: ContentItem, at index: Int, cornerRadius: CGFloat) -> some View {
        ContentItemCard(
            item: item,
            cornerRadius: cornerRadius,
            numberOfColumns: numberOfColumns,
            isSelectionMode: viewModel.isSelectionMode,
            onSelectionTap: { viewModel.toggleItemSelection(item.safeId) }
        )
        .id(item.safeId)
        .allowsHitTesting(!isPinching)
        .onDrag { NSItemProvider(object: item.safeId.uuidString as NSString) }
        .onAppear {
            if item == filteredItems.last {
                _ = dataService.loadMoreContentItems()
            }
        }
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: cornerRadius))
        .contextMenu {
            if !viewModel.isSelectionMode {
                ContentItemContextMenu(
                    item: item,
                    dataService: dataService,
                    onStorageStatsRefresh: { storageStatsRefreshTrigger += 1 },
                    onDeleteRequest: {
                        itemToDelete = item
                        showDeleteConfirmation = true
                    }
                )
            }
        }
    }

    // MARK: - Overlay sélection
    private func selectionOverlay(for item: ContentItem) -> some View {
        Group {
            if viewModel.isSelectionMode {
                VStack {
                    HStack {
                        
                        Button(action: {
                            viewModel.toggleItemSelection(item.safeId)
                        }) {
                            Image(systemName: viewModel.selectedItems.contains(item.safeId) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(viewModel.selectedItems.contains(item.safeId) ? .red : .gray)
                                .font(.system(size: 22))
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                        }
                        .padding(8)
                        
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
    }

    // MARK: - Pinch Gesture
    private var pinchGesture: some Gesture {
        MagnificationGesture(minimumScaleDelta: 0)
            .onChanged { newScale in
                isPinching = true
                // Toujours permettre le pinch, pas de limites
                pinchScale = max(0.98, min(newScale, 1.02))
            }
            .onEnded { finalScale in
                var newColumns = numberOfColumns
                
                if finalScale > 1.08 {
                    // Pinch vers l'extérieur (plus de colonnes)
                    if numberOfColumns < maxColumns {
                        newColumns = numberOfColumns + 1
                    } else {
                        // Boucle : du maximum au minimum
                        newColumns = minColumns
                    }
                } else if finalScale < 0.92 {
                    // Pinch vers l'intérieur (moins de colonnes)
                    if numberOfColumns > minColumns {
                        newColumns = numberOfColumns - 1
                    } else {
                        // Boucle : du minimum au maximum
                        newColumns = maxColumns
                    }
                }
                
                if newColumns != numberOfColumns {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.9, blendDuration: 0.15)) {
                        numberOfColumns = newColumns
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                
                withAnimation(.easeInOut(duration: 0.18)) {
                    pinchScale = 1.0
                    isPinching = false
                }
            }
    }
}


#Preview {
    MainView()
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
        let screenHeight = UIScreen.main.bounds.height
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
}
