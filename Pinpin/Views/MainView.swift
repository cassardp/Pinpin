//
//  MainView.swift
//  Neeed2
//
//  Vue principale de l'application
//

import SwiftUI
import UIKit

struct MainView: View {
    @StateObject private var contentService = ContentServiceCoreData()
    @StateObject private var sharedContentService: SharedContentService
    @StateObject private var userPreferences = UserPreferences.shared
    @State private var storageStatsRefreshTrigger = 0
    @State private var isMenuOpen = false
    @State private var isSettingsOpen = false
    @State private var isAboutOpen = false
    @State private var settingsDetent: PresentationDetent = .medium
    @State private var isSwipingHorizontally: Bool = false
    @State private var searchQuery: String = ""
    @State private var showSearchBar: Bool = false
    @State private var scrollOffset: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    @AppStorage("numberOfColumns") private var numberOfColumns: Int = 2

    // Bornes de colonnes
    private let minColumns: Int = 2
    private let maxColumns: Int = 4

    // État du pinch (feedback + verrou gestures)
    @State private var pinchScale: CGFloat = 1.0
    @State private var isPinching: Bool = false
    
    // Multi-sélection
    @State private var isSelectionMode: Bool = false
    @State private var selectedItems: Set<UUID> = []

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

    @State private var selectedContentType: String? = nil
    
    // Nom de la catégorie actuelle pour affichage
    /*
    private var currentCategoryName: String {
        guard let selectedType = selectedContentType,
              let contentType = ContentType(rawValue: selectedType) else {
            return "All"
        }
        return contentType.displayName
    }
    */

    // FetchRequest pour récupérer tous les items
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ContentItem.createdAt, ascending: false)],
        animation: nil)
    private var allContentItems: FetchedResults<ContentItem>

    // Items filtrés selon le type sélectionné et la recherche
    private var filteredItems: [ContentItem] {
        let items = Array(allContentItems)
        // Filtre par type
        let typeFiltered: [ContentItem]
        if let selectedType = selectedContentType {
            typeFiltered = items.filter { $0.contentType == selectedType }
        } else {
            typeFiltered = items
        }

        // Filtre par requête texte
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return typeFiltered }

        return typeFiltered.filter { item in
            let title = item.title?.lowercased() ?? ""
            let description = (item.metadataDict["best_description"] ?? item.itemDescription ?? "").lowercased()
            let url = item.url?.lowercased() ?? ""
            let metadataValues = item.metadataDict.values.joined(separator: " ").lowercased()
            return title.contains(query)
                || description.contains(query)
                || url.contains(query)
                || metadataValues.contains(query)
        }
    }

    init() {
        let contentService = ContentServiceCoreData()
        self._contentService = StateObject(wrappedValue: contentService)
        self._sharedContentService = StateObject(wrappedValue: SharedContentService(contentService: contentService))
    }

    var body: some View {
        PushingSideDrawer(
            isOpen: $isMenuOpen,
            width: UIScreen.main.bounds.width * 0.8
        ) {
            // Contenu principal
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea(.keyboard)

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            Color.clear.frame(height: 0).id("top")
                            
                            // Barre de navigation combinée
                            NavigationBarView(
                                isSelectionMode: $isSelectionMode,
                                selectedItems: $selectedItems,
                                searchQuery: $searchQuery,
                                showSearchBar: $showSearchBar,
                                isMenuOpen: $isMenuOpen,
                                onSelectAll: selectAllItems,
                                onDeleteSelected: deleteSelectedItems,
                                filteredItemsCount: filteredItems.count
                            )

                            if filteredItems.isEmpty {
                                EmptyStateView()
                            } else {
                                // Conteneur de la grille (feedback visuel + verrou taps pendant pinch)
                                VStack(spacing: 0) {
                                    PinterestLayoutWrapper(numberOfColumns: numberOfColumns, itemSpacing: dynamicSpacing) {
                                        ForEach(filteredItems, id: \.safeId) { item in
                                            if let index = filteredItems.firstIndex(of: item) {
                                                buildContentCard(for: item, at: index, cornerRadius: dynamicCornerRadius)
                                                    .overlay(
                                                        // Overlay de sélection
                                                        Group {
                                                            if isSelectionMode {
                                                                VStack {
                                                                    HStack {
                                                                        Spacer()
                                                                        Button(action: {
                                                                            toggleItemSelection(item.safeId)
                                                                        }) {
                                                                            Image(systemName: selectedItems.contains(item.safeId) ? "checkmark.circle.fill" : "circle")
                                                                                .foregroundColor(selectedItems.contains(item.safeId) ? .red : .gray)
                                                                                .font(.system(size: 20))
                                                                                .background(Color.white)
                                                                                .clipShape(Circle())
                                                                        }
                                                                        .padding(8)
                                                                    }
                                                                    Spacer()
                                                                }
                                                            }
                                                        }
                                                    )
                                            } else {
                                                buildContentCard(for: item, at: 0, cornerRadius: dynamicCornerRadius)
                                            }
                                        }
                                    }
                                }
                                .id(selectedContentType ?? "all") // Force la recréation lors du changement de filtre
                                .scaleEffect(isPinching ? pinchScale : 1.0, anchor: .center)
                                .animation(.linear(duration: 0.08), value: pinchScale)
                                .allowsHitTesting(!isPinching) // bloque taps/long-press sur la grille pendant le pinch

                                if contentService.isLoadingMore {
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
                                        selectedContentType: selectedContentType,
                                        filteredItems: filteredItems
                                    )
                                    .padding(.top, 50)
                                    .id(storageStatsRefreshTrigger)
                                }

                                // Padding bottom pour éviter que le contenu soit masqué par la barre flottante
                                Color.clear.frame(height: 120)
                            }
                        }
                        .padding(.horizontal, 10)
                        .onChange(of: selectedContentType) {
                            withTransaction(Transaction(animation: nil)) {
                                proxy.scrollTo("top", anchor: .top)
                            }
                        }
                        .animation(nil, value: selectedContentType) // Désactive toute animation implicite
                    }
                    .scrollIndicators(.hidden)
                    .refreshable { contentService.loadContentItems() }
                    .scrollDisabled(isMenuOpen || isSettingsOpen)
                    // Pinch prioritaire + verrou en butée + blocage du swipe horizontal pendant pinch
                    .highPriorityGesture(
                        MagnificationGesture(minimumScaleDelta: 0)
                            .onChanged { newScale in
                                isPinching = true
                                isSwipingHorizontally = true // neutralise le swipe d'ouverture du menu côté contenu

                                // Direction du geste
                                let goesSmaller = newScale < 1.0   // pinch-in => moins de colonnes
                                let goesBigger  = newScale > 1.0   // pinch-out => plus de colonnes

                                let canZoomIn  = numberOfColumns > minColumns
                                let canZoomOut = numberOfColumns < maxColumns

                                // Si en butée et mauvaise direction, on neutralise le feedback (pas de "pump")
                                if (goesSmaller && !canZoomIn) || (goesBigger && !canZoomOut) {
                                    pinchScale = 1.0
                                    return
                                }

                                // Feedback visuel doux
                                pinchScale = max(0.98, min(newScale, 1.02))
                            }
                            .onEnded { finalScale in
                                let canZoomIn  = numberOfColumns > minColumns
                                let canZoomOut = numberOfColumns < maxColumns

                                var newColumns = numberOfColumns
                                if finalScale > 1.08, canZoomOut {
                                    newColumns = min(numberOfColumns + 1, maxColumns)
                                } else if finalScale < 0.92, canZoomIn {
                                    newColumns = max(numberOfColumns - 1, minColumns)
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
                                    isSwipingHorizontally = false
                                }
                            }
                    )
                }
                
                // Barre de recherche flottante en overlay
                FloatingSearchBar(
                    searchQuery: $searchQuery,
                    showSearchBar: $showSearchBar
                )
            }
            // Bouclier overlay : avale drags & taps pendant le pinch (empêche ouverture menu et taps parasites)
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
            // Menu latéral
            FilterMenuView(
                selectedContentType: $selectedContentType,
                isSwipingHorizontally: $isSwipingHorizontally,
                onOpenSettings: { isSettingsOpen = true },
                onOpenAbout: { isAboutOpen = true }
            )
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            // Réinitialiser la recherche au démarrage
            searchQuery = ""
            showSearchBar = false
            
            Task {
                if sharedContentService.hasNewSharedContent() {
                    await sharedContentService.processPendingSharedContents()
                }
            }
            contentService.loadContentItems()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task {
                if sharedContentService.hasNewSharedContent() {
                    await sharedContentService.processPendingSharedContents()
                }
            }
        }
        .sheet(isPresented: $isSettingsOpen) {
            SettingsView(isSwipingHorizontally: $isSwipingHorizontally)
                .presentationDetents([.medium, .large], selection: $settingsDetent)
                .presentationDragIndicator(.hidden)
        }
    }
    
    // MARK: - Fonctions de multi-sélection
    
    private func toggleItemSelection(_ itemId: UUID) {
        if selectedItems.contains(itemId) {
            selectedItems.remove(itemId)
        } else {
            selectedItems.insert(itemId)
        }
    }
    
    private func selectAllItems() {
        // Select all currently filtered items
        selectedItems = Set(filteredItems.map { $0.safeId })
    }
    
    private func deleteSelectedItems() {
        let itemsToDelete = filteredItems.filter { selectedItems.contains($0.safeId) }
        
        for item in itemsToDelete {
            contentService.deleteContentItem(item)
        }
        
        // Réinitialiser la sélection
        selectedItems.removeAll()
        isSelectionMode = false
        
        // Rafraîchir les stats
        storageStatsRefreshTrigger += 1
    }

    @ViewBuilder
    private func buildContentCard(for item: ContentItem, at index: Int, cornerRadius: CGFloat) -> some View {
        ContentItemCard(
            item: item, 
            cornerRadius: cornerRadius, 
            numberOfColumns: numberOfColumns, 
            isSelectionMode: isSelectionMode,
            onSelectionTap: { toggleItemSelection(item.safeId) }
        )
            .id(item.safeId)
            .allowsHitTesting(!isSwipingHorizontally && !isPinching)
            // Animation uniquement pour la suppression, pas pour le filtrage
            .animation(isSelectionMode ? .easeInOut(duration: 0.4) : nil, value: filteredItems)
            .onDrag { NSItemProvider(object: item.safeId.uuidString as NSString) }
            .onAppear {
                if item == filteredItems.last {
                    contentService.loadMoreContentItems()
                }
            }
            .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: cornerRadius))
            .contextMenu {
                if !isSelectionMode {
                    ContentItemContextMenu(
                        item: item,
                        contentService: contentService,
                        onStorageStatsRefresh: { storageStatsRefreshTrigger += 1 }
                    )
                }
            }
    }
}

// MARK: - Preference Key pour le scroll offset
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    MainView()
}
