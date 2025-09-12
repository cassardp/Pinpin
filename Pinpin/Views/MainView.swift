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
    @State private var isSwipingHorizontally: Bool = false
    @AppStorage("numberOfColumns") private var numberOfColumns: Int = 2

    private let minColumns: Int = 1
    private let maxColumns: Int = 4
    
    // --- Pinch state (nouveau) ---
    @State private var pinchScale: CGFloat = 1.0           // échelle en direct pendant le pinch
    @State private var isPinching: Bool = false            // pour n’appliquer le scale que durant le geste
    
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
                        LazyVStack(spacing: 0) {
                            // Anchor invisible pour le scroll reset si besoin
                            Color.clear.frame(height: 0).id("top")
                            
                            if filteredItems.isEmpty {
                                EmptyStateView()
                            } else {
                                // --- Conteneur zoomable : applique le retour visuel de contraction/expansion ---
                                VStack(spacing: 0) {
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
                                }
                                // Le scale est appliqué uniquement pendant le geste
                                .scaleEffect(isPinching ? pinchScale : 1.0, anchor: .center)
                                .animation(.linear(duration: 0.08), value: pinchScale) // réactivité du retour visuel

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
                            // On peut remonter au top lors d’un changement de filtre,
                            // mais on évite de forcer au top lors d’un pinch.
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
                    // --- Geste de pincement donné en priorité sur le scroll pour éviter les confusions ---
                    .highPriorityGesture(
                        MagnificationGesture(minimumScaleDelta: 0)
                            .onChanged { newScale in
                                isPinching = true

                                // Direction du geste
                                let goesSmaller = newScale < 1.0   // pinch-in => moins de colonnes
                                let goesBigger  = newScale > 1.0   // pinch-out => plus de colonnes

                                let canZoomIn  = numberOfColumns > minColumns
                                let canZoomOut = numberOfColumns < maxColumns

                                // Si on est en butée et que le geste va dans la mauvaise direction,
                                // on "lock" le feedback visuel à 1.0 (aucun effet).
                                if (goesSmaller && !canZoomIn) || (goesBigger && !canZoomOut) {
                                    pinchScale = 1.0
                                    return
                                }

                                // Sinon, on applique un retour visuel doux (clamp resserré)
                                // 0.9–1.1 par défaut (tu peux ajuster)
                                let clamped = max(0.9, min(newScale, 1.1))
                                pinchScale = clamped
                            }
                            .onEnded { finalScale in
                                let canZoomIn  = numberOfColumns > minColumns
                                let canZoomOut = numberOfColumns < maxColumns

                                var newColumns = numberOfColumns

                                // Seuils inchangés, mais on vérifie la possibilité
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
                                }
                            }
                    )
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
            .animation(.easeInOut(duration: 0.4), value: filteredItems)
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
