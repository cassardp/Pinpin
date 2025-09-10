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
    @State private var dragTranslation: CGFloat = 0
    @State private var gestureDirection: GestureDirection? = nil {
        didSet {
            isSwipingHorizontally = gestureDirection == .horizontal
        }
    }
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
    
    enum GestureDirection {
        case horizontal
        case vertical
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
    
    private func clampedTranslation(_ dx: CGFloat, max: CGFloat) -> CGFloat {
        return Swift.max(Swift.min(dx, max), -max)
    }
    
    var body: some View {
        GeometryReader { geo in
            let menuWidth = geo.size.width * 0.8

            HStack(spacing: 0) {
                // Menu à gauche
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
                .frame(width: menuWidth)

                // Contenu principal au centre
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
                        .scrollDisabled(gestureDirection == .horizontal || isMenuOpen || isSettingsOpen)
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
                    
                    // Overlay pour fermer les menus
                    ZStack {
                        if isMenuOpen {
                            Color.black.opacity(0.001) // invisible mais cliquable
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    // Haptic feedback sourd pour la fermeture du menu
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
                                    impactFeedback.impactOccurred()
                                    withAnimation {
                                        isMenuOpen = false
                                        isSettingsOpen = false
                                    }
                                }
                                .ignoresSafeArea()
                        }
                    }
                    .frame(width: geo.size.width)
                }
            }
            .offset(x: calculateOffset(menuWidth: menuWidth))
            .gesture(
                DragGesture(minimumDistance: 10, coordinateSpace: .local)
                    .onChanged { value in
                        let dx = value.translation.width
                        let dy = value.translation.height
                        
                        // Déterminer la direction du geste au premier mouvement significatif
                        if gestureDirection == nil {
                            gestureDirection = abs(dx) > abs(dy) ? .horizontal : .vertical
                        }
                        
                        // Ne traiter que les gestes horizontaux
                        guard gestureDirection == .horizontal else { return }
                        
                        // Calculer dragTranslation selon l'état du menu
                        if (dx < 0 && !isMenuOpen) || (dx > 0 && isMenuOpen) {
                            dragTranslation = 0
                        } else {
                            dragTranslation = clampedTranslation(dx, max: geo.size.width * 0.8)
                        }
                    }
                    .onEnded { value in
                        defer { gestureDirection = nil }
                        
                        guard gestureDirection == .horizontal else { return }
                        
                        let effectiveTranslation = dragTranslation + value.predictedEndTranslation.width
                        let threshold = geo.size.width * 0.25
                        
                        let shouldToggleMenu = (effectiveTranslation > threshold && !isMenuOpen) || 
                                             (effectiveTranslation < -threshold && isMenuOpen)
                        
                        withAnimation(.easeOut(duration: 0.25)) {
                            if shouldToggleMenu {
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                isMenuOpen.toggle()
                            }
                            dragTranslation = 0
                        }
                    }
            )
            .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.25), value: isMenuOpen)
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
    
    private func calculateOffset(menuWidth: CGFloat) -> CGFloat {
        let baseOffset = -menuWidth
        let offset = isMenuOpen ? menuWidth : 0
        return baseOffset + offset + dragTranslation
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
