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
    @State private var storageStatsRefreshTrigger = 0
    @State private var isMenuOpen = false
    @State private var isSettingsOpen = false
    @State private var isAboutOpen = false
    @GestureState private var dragOffset: CGFloat = 0
    @State private var dragTranslation: CGFloat = 0
    @State private var isSwipingHorizontally: Bool = false
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
                                    MasonryGrid(
                                        items: filteredItems,
                                        columns: 2,
                                        spacing: 10,
                                        content: { item in
                                            if let index = filteredItems.firstIndex(of: item) {
                                                buildContentCard(for: item, at: index)
                                            } else {
                                                buildContentCard(for: item, at: 0)
                                            }
                                        }
                                    )
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

                                    Color.clear.frame(height: 100)
                                }
                            }
                            .padding(.horizontal, 10)
                            .onChange(of: selectedContentType) {
                                withTransaction(Transaction(animation: nil)) {
                                    proxy.scrollTo("top", anchor: .top)
                                }
                            }

                        }
                        .simultaneousGesture(
                            DragGesture().onChanged { value in
                                let dx = value.translation.width
                                let dy = value.translation.height
                                let angle = atan2(dy, dx) * 180 / .pi
                                isSwipingHorizontally = abs(angle) < 30
                            }
                        )
                        .scrollIndicators(.hidden)
                        .refreshable {
                            contentService.loadContentItems()
                        }
                        .disabled(isSwipingHorizontally || isMenuOpen || isSettingsOpen)
                    }
                    
                    // Overlay pour fermer les menus
                    ZStack {
                        if isMenuOpen {
                            Color.black.opacity(0.001) // invisible mais cliquable
                                .contentShape(Rectangle())
                                .onTapGesture {
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
                    .updating($dragOffset) { value, state, _ in
                        let dx = value.translation.width
                        state = clampedTranslation(dx, max: geo.size.width * 0.8)
                    }
                    .onChanged { value in
                        let dx = value.translation.width
                        let dy = value.translation.height
                        let angle = atan2(dy, dx) * 180 / .pi
                        isSwipingHorizontally = abs(angle) < 30
                        if dx < 0 && !isMenuOpen {
                            return
                        }
                        if dx > 0 && isMenuOpen {
                            return
                        }
                        dragTranslation = clampedTranslation(dx, max: geo.size.width * 0.8)
                    }
                    .onEnded { value in
                        let predicted = value.predictedEndTranslation.width
                        let effectiveTranslation = dragTranslation + predicted
                        let threshold = geo.size.width * 0.3

                        if effectiveTranslation < -threshold && !isMenuOpen {
                            return
                        }
                        if effectiveTranslation > threshold && isMenuOpen {
                            return
                        }

                        withAnimation(.easeOut(duration: 0.25)) {
                            if effectiveTranslation > threshold {
                                isMenuOpen = true
                            } else if effectiveTranslation < -threshold {
                                isMenuOpen = false
                            }
                            dragTranslation = 0
                        }

                        isSwipingHorizontally = false
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
    private func buildContentCard(for item: ContentItem, at index: Int) -> some View {
        ContentItemCard(item: item)
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
            .contextMenu {
                buildContextMenu(for: item)
            }
    }
    
    @ViewBuilder
    private func buildContextMenu(for item: ContentItem) -> some View {
        if let url = item.url, !url.isEmpty {
            Button(action: {
                UIPasteboard.general.string = url
            }) {
                Label("Copy link", systemImage: "doc.on.doc")
            }
        }

        Button(action: {
            if let url = item.url, !url.isEmpty, let shareURL = URL(string: url) {
                let activityVC = UIActivityViewController(
                    activityItems: [shareURL],
                    applicationActivities: nil
                )
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.rootViewController?.present(activityVC, animated: true)
                }
            }
        }) {
            Label("Share", systemImage: "square.and.arrow.up")
        }

        Divider()

        Button(role: .destructive, action: {
            contentService.deleteContentItem(item)
            storageStatsRefreshTrigger += 1
        }) {
            Label("Delete", systemImage: "trash")
        }
    }
}
