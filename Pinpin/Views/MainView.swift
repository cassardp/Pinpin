//
//  MainView.swift
//  Neeed2
//
//  Vue principale de l'application
//

import SwiftUI

struct MainView: View {
    @StateObject private var contentService = ContentServiceCoreData()
    @StateObject private var sharedContentService: SharedContentService
    @StateObject private var userPreferences = UserPreferences.shared
    @State private var storageStatsRefreshTrigger = 0
    @State private var isMenuOpen = false
    @State private var isSettingsOpen = false
    @State private var isAboutOpen = false
    @State private var isSwipingHorizontally: Bool = false
    @AppStorage("numberOfColumns") private var numberOfColumns: Int = 2
    
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
        if userPreferences.disableCornerRadius {
            return 0
        }
        switch numberOfColumns {
        case 1: return 20
        case 2: return 14
        case 3: return 10
        case 4: return 8
        default: return 14
        }
    }
    
    @State private var selectedContentType: String? = nil
    
    // FetchRequest pour récupérer tous les items
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ContentItem.createdAt, ascending: false)],
        animation: nil)
    private var allContentItems: FetchedResults<ContentItem>
    
    // Items filtrés selon le type sélectionné
    private var filteredItems: [ContentItem] {
        let items = Array(allContentItems)
        guard let selectedType = selectedContentType else {
            return items
        }
        return items.filter { $0.contentType == selectedType }
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
                        LazyVStack {
                            // Anchor invisible pour le scroll reset
                            Color.clear.frame(height: 0).id("top")
                            
                            if filteredItems.isEmpty {
                                EmptyStateView()
                            } else {
                                PinterestLayoutWrapper(numberOfColumns: numberOfColumns, itemSpacing: dynamicSpacing) {
                                    ForEach(filteredItems, id: \.safeId) { item in
                                        if let index = filteredItems.firstIndex(of: item) {
                                            buildContentCard(for: item, at: index, cornerRadius: dynamicCornerRadius)
                                        } else {
                                            buildContentCard(for: item, at: 0, cornerRadius: dynamicCornerRadius)
                                        }
                                    }
                                }
                                .animation(nil, value: filteredItems)

                                if contentService.isLoadingMore {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                            .scaleEffect(0.8)
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

                                Color.clear.frame(height: 40)
                            }
                        }
                        .padding(.horizontal, 10)
                        .onChange(of: selectedContentType) {
                            withTransaction(Transaction(animation: nil)) {
                                proxy.scrollTo("top", anchor: .top)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .refreshable {
                        contentService.loadContentItems()
                    }
                    .scrollDisabled(isMenuOpen || isSettingsOpen)
                    .onTapGesture(count: 2) {
                        // Double tap pour cycler entre les nombres de colonnes
                        withAnimation(.easeInOut(duration: 0.3)) {
                            numberOfColumns = numberOfColumns == 4 ? 1 : numberOfColumns + 1
                        }
                        // Remonter en haut de la liste
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo("top", anchor: .top)
                        }
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                }
            }
        } drawer: {
            // Menu latéral
            FilterMenuView(
                selectedContentType: $selectedContentType,
                isSwipingHorizontally: $isSwipingHorizontally,
                onOpenSettings: {
                    isSettingsOpen = true
                },
                onOpenAbout: {
                    isAboutOpen = true
                }
            )
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
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
                .presentationDetents([.large])
        }
    }
    
    @ViewBuilder
    private func buildContentCard(for item: ContentItem, at index: Int, cornerRadius: CGFloat) -> some View {
        ContentItemCard(item: item, cornerRadius: cornerRadius, numberOfColumns: numberOfColumns)
            .id(item.safeId)
            .allowsHitTesting(!isSwipingHorizontally)
            .animation(nil, value: filteredItems)
            .onDrag {
                NSItemProvider(object: item.safeId.uuidString as NSString)
            }
            .onAppear {
                if item == filteredItems.last {
                    contentService.loadMoreContentItems()
                }
            }
            .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: cornerRadius))
            .contextMenu {
                ContentItemContextMenu(
                    item: item,
                    contentService: contentService,
                    onStorageStatsRefresh: { storageStatsRefreshTrigger += 1 }
                )
            }
    }
    

}


#Preview {
    MainView()
}
