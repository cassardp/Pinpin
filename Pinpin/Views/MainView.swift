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

    // État du pinch
    @State private var pinchScale: CGFloat = 1.0
    @State private var isPinching: Bool = false
    
    // Multi-sélection
    @State private var isSelectionMode: Bool = false
    @State private var selectedItems: Set<UUID> = []

    // Hauteur du clavier pour ajuster la barre flottante
    @State private var keyboardHeight: CGFloat = 0

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

    // FetchRequest CoreData
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ContentItem.createdAt, ascending: false)],
        animation: .default)
    private var allContentItems: FetchedResults<ContentItem>

    // Items filtrés
    private var filteredItems: [ContentItem] {
        let items = Array(allContentItems)
        let typeFiltered: [ContentItem]
        if let selectedType = selectedContentType {
            typeFiltered = items.filter { $0.contentType == selectedType }
        } else {
            typeFiltered = items
        }

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

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            Color.clear.frame(height: 0).id("top")

                            if filteredItems.isEmpty {
                                EmptyStateView()
                            } else {
                                VStack(spacing: 0) {
                                    PinterestLayoutWrapper(numberOfColumns: numberOfColumns, itemSpacing: dynamicSpacing) {
                                        ForEach(filteredItems, id: \.safeId) { item in
                                            if let index = filteredItems.firstIndex(of: item) {
                                                buildContentCard(for: item, at: index, cornerRadius: dynamicCornerRadius)
                                                    .overlay(selectionOverlay(for: item))
                                            } else {
                                                buildContentCard(for: item, at: 0, cornerRadius: dynamicCornerRadius)
                                            }
                                        }
                                    }
                                }
                                .id(selectedContentType ?? "all")
                                .scaleEffect(isPinching ? pinchScale : 1.0, anchor: .center)
                                .animation(.linear(duration: 0.08), value: pinchScale)
                                .allowsHitTesting(!isPinching)

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
                                    .padding(.bottom, 30)
                                    .id(storageStatsRefreshTrigger)
                                }
                            }
                        }
                        .padding(.horizontal, 10)
                        .onChange(of: selectedContentType) {
                            withTransaction(Transaction(animation: nil)) {
                                proxy.scrollTo("top", anchor: .top)
                            }
                        }
                        .onChange(of: searchQuery) {
                            if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                withTransaction(Transaction(animation: nil)) {
                                    proxy.scrollTo("top", anchor: .top)
                                }
                            }
                        }
                        .onChange(of: isMenuOpen) {
                            if isMenuOpen {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    showSearchBar = false
                                }
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                        }
                        .animation(nil, value: selectedContentType)
                    }
                    .scrollIndicators(.hidden)
                    .refreshable { contentService.loadContentItems() }
                    .scrollDisabled(isMenuOpen || isSettingsOpen)
                    .highPriorityGesture(pinchGesture)
                }

                // ✅ Overlay pour fermer searchbar
                if showSearchBar {
                    Color.black.opacity(0.001)
                        .ignoresSafeArea()
                        .onTapGesture {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                                showSearchBar = false
                            }
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
                selectedContentType: $selectedContentType,
                isSwipingHorizontally: $isSwipingHorizontally,
                onOpenAbout: { isAboutOpen = true }
            )
        }
        .onAppear {
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
        // Suivi hauteur clavier pour remonter la searchbar au-dessus
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
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
        .sheet(isPresented: $isSettingsOpen) {
            SettingsView(isSwipingHorizontally: $isSwipingHorizontally)
                .presentationDetents([.medium, .large], selection: $settingsDetent)
                .presentationDragIndicator(.hidden)
        }
        .safeAreaInset(edge: .bottom) {
            FloatingSearchBar(
                searchQuery: $searchQuery,
                showSearchBar: $showSearchBar,
                isSelectionMode: $isSelectionMode,
                selectedItems: $selectedItems,
                showSettings: $isSettingsOpen,
                isMenuOpen: $isMenuOpen,
                totalPinsCount: filteredItems.count,
                onSelectAll: {
                    selectedItems = Set(filteredItems.map { $0.safeId })
                },
                onDeleteSelected: {
                    deleteSelectedItems()
                },
                bottomPadding: keyboardHeight > 0 ? 0 : 12
            )
        }
    }

    // MARK: - Sélection
    private func toggleItemSelection(_ itemId: UUID) {
        if selectedItems.contains(itemId) {
            selectedItems.remove(itemId)
        } else {
            selectedItems.insert(itemId)
        }
    }

    private func deleteSelectedItems() {
        let itemsToDelete = filteredItems.filter { selectedItems.contains($0.safeId) }
        withAnimation(.easeInOut(duration: 0.25)) {
            for item in itemsToDelete {
                contentService.deleteContentItem(item)
            }
            selectedItems.removeAll()
            isSelectionMode = false
            storageStatsRefreshTrigger += 1
        }
    }

    // MARK: - Card
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
                Button(role: .destructive) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        contentService.deleteContentItem(item)
                        if isSelectionMode {
                            selectedItems.remove(item.safeId)
                            if selectedItems.isEmpty { isSelectionMode = false }
                        }
                        storageStatsRefreshTrigger += 1
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    // MARK: - Overlay sélection
    private func selectionOverlay(for item: ContentItem) -> some View {
        Group {
            if isSelectionMode {
                VStack {
                    HStack {
                        
                        Button(action: {
                            toggleItemSelection(item.safeId)
                        }) {
                            Image(systemName: selectedItems.contains(item.safeId) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedItems.contains(item.safeId) ? .red : .gray)
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
                isSwipingHorizontally = true
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
                    isSwipingHorizontally = false
                }
            }
    }
}

// MARK: - ScrollOffsetPreferenceKey
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    MainView()
}
