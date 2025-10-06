import SwiftUI

struct MainContentScrollView: View {
    @Binding var selectedContentType: String?
    @Binding var searchQuery: String
    @Binding var isMenuOpen: Bool
    @Binding var isSettingsOpen: Bool
    @Binding var numberOfColumns: Int
    @Binding var scrollProgress: CGFloat
    @Binding var hapticTrigger: Int
    
    @StateObject private var userPreferences = UserPreferences.shared
    
    let filteredItems: [ContentItem]
    let totalItemsCount: Int
    let displayLimit: Int
    let dynamicSpacing: CGFloat
    let dynamicCornerRadius: CGFloat
    let isSelectionMode: Bool
    let selectedItems: Set<UUID>
    let screenBounds: CGRect
    let syncServiceLastSaveDate: Date
    let storageStatsRefreshTrigger: Int
    let dataService: DataService
    let minColumns: Int
    let maxColumns: Int
    
    let onCategoryChange: (ScrollViewProxy) -> Void
    let onSearchQueryChange: (String, ScrollViewProxy) -> Void
    let onMenuStateChange: (Bool) -> Void
    let onRefresh: () async -> Void
    let onLoadMore: (Int) -> Void
    let onToggleSelection: (UUID) -> Void
    let onDeleteItem: (ContentItem) -> Void
    let onStorageStatsRefresh: () -> Void
    
    // MARK: - Pinch State
    @State private var isPinching: Bool = false
    @State private var pinchScale: CGFloat = 1.0
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                contentStack
                    .onChange(of: selectedContentType) { _, _ in
                        onCategoryChange(proxy)
                    }
                    .onChange(of: searchQuery) { _, newValue in
                        onSearchQueryChange(newValue, proxy)
                    }
                    .onChange(of: isMenuOpen) { _, newValue in
                        onMenuStateChange(newValue)
                    }
                    .animation(nil, value: selectedContentType)
                    .animation(nil, value: syncServiceLastSaveDate)
                    .id(syncServiceLastSaveDate)
            }
            .scrollIndicators(.hidden)
            .refreshable {
                await onRefresh()
            }
            .scrollDisabled(isMenuOpen || isSettingsOpen)
            .highPriorityGesture(pinchGesture)
            .simultaneousGesture(scrollDragGesture)
        }
    }
    
    private var contentStack: some View {
        LazyVStack(spacing: 0) {
            Color.clear.frame(height: 0).id("top")
            
            if filteredItems.isEmpty {
                emptyStateView
            } else {
                // Timeline pour "All" si activée, sinon grille classique
                if selectedContentType == nil && userPreferences.enableTimelineView {
                    TimelineGroupedView(
                        items: filteredItems,
                        numberOfColumns: numberOfColumns,
                        dynamicSpacing: dynamicSpacing,
                        dynamicCornerRadius: dynamicCornerRadius,
                        isPinching: isPinching,
                        pinchScale: pinchScale,
                        isSelectionMode: isSelectionMode,
                        selectedItems: selectedItems,
                        dataService: dataService,
                        onLoadMore: onLoadMore,
                        onToggleSelection: onToggleSelection,
                        onDeleteItem: onDeleteItem,
                        onStorageStatsRefresh: onStorageStatsRefresh
                    )
                } else {
                    ContentGridView(
                        items: filteredItems,
                        numberOfColumns: numberOfColumns,
                        dynamicSpacing: dynamicSpacing,
                        dynamicCornerRadius: dynamicCornerRadius,
                        isPinching: isPinching,
                        pinchScale: pinchScale,
                        selectedContentType: selectedContentType,
                        isSelectionMode: isSelectionMode,
                        selectedItems: selectedItems,
                        dataService: dataService,
                        onLoadMore: onLoadMore,
                        onToggleSelection: onToggleSelection,
                        onDeleteItem: onDeleteItem,
                        onStorageStatsRefresh: onStorageStatsRefresh
                    )
                }
                
                loadingIndicator
                storageStats
            }
        }
        .padding(.horizontal, 10)
        .overlay(pinchShield)
    }
    
    // MARK: - Pinch Shield
    @ViewBuilder
    private var pinchShield: some View {
        if isPinching {
            Color.clear
                .contentShape(Rectangle())
                .highPriorityGesture(DragGesture(minimumDistance: 0))
                .highPriorityGesture(TapGesture())
                .allowsHitTesting(true)
        }
    }
    
    // MARK: - Pinch Gesture
    private var pinchGesture: some Gesture {
        MagnificationGesture(minimumScaleDelta: 0)
            .onChanged { newScale in
                isPinching = true
                pinchScale = max(0.98, min(newScale, 1.02))
            }
            .onEnded { finalScale in
                var newColumns = numberOfColumns
                
                if finalScale > 1.08 {
                    if numberOfColumns < maxColumns {
                        newColumns = numberOfColumns + 1
                    } else {
                        newColumns = minColumns
                    }
                } else if finalScale < 0.92 {
                    if numberOfColumns > minColumns {
                        newColumns = numberOfColumns - 1
                    } else {
                        newColumns = maxColumns
                    }
                }
                
                if newColumns != numberOfColumns {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.9, blendDuration: 0.15)) {
                        numberOfColumns = newColumns
                    }
                    hapticTrigger += 1
                }
                
                withAnimation(.easeInOut(duration: 0.18)) {
                    pinchScale = 1.0
                    isPinching = false
                }
            }
    }
    
    // MARK: - Scroll Drag Gesture
    private var scrollDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let dy = value.translation.height
                if dy < -30 {
                    scrollProgress = 1.0
                } else if dy > 30 {
                    scrollProgress = 0.0
                }
            }
            .onEnded { value in
                let dy = value.translation.height
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if dy < -50 {
                        scrollProgress = 1.0
                    } else if dy > 50 {
                        scrollProgress = 0.0
                    }
                }
            }
    }
    
    private var emptyStateView: some View {
        GeometryReader { geometry in
            EmptyStateView()
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(height: screenBounds.height - 150)
    }
    
    @ViewBuilder
    private var loadingIndicator: some View {
        if displayLimit < totalItemsCount {
            HStack {
                Spacer()
                ProgressView().scaleEffect(0.8)
                Text("Loading...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.vertical, 20)
            .onAppear {
                // Force un "load more" lorsque l’on atteint visuellement le bas
                // Utiliser l’index du dernier item actuellement affiché
                onLoadMore(max(0, displayLimit - 1))
            }
        }
    }
    
    @ViewBuilder
    
    private var storageStats: some View {
        if !filteredItems.isEmpty {
            StorageStatsView(
                selectedContentType: selectedContentType,
                filteredItems: filteredItems
            )
            .padding(.top, 50)
            .padding(.bottom, 90)
            .id(storageStatsRefreshTrigger)
        }
    }
}
