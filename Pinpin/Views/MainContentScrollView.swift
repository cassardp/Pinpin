import SwiftUI

struct MainContentScrollView: View {
    @Binding var selectedContentType: String?
    @Binding var searchQuery: String
    @Binding var isMenuOpen: Bool
    @Binding var isSettingsOpen: Bool
    @Binding var numberOfColumns: Int
    @Binding var scrollProgress: CGFloat
    @Binding var hapticTrigger: Int
    
    private let userPreferences = UserPreferences.shared
    
    let filteredItems: [ContentItem]
    let totalItemsCount: Int
    let displayLimit: Int
    let dynamicSpacing: CGFloat
    let dynamicCornerRadius: CGFloat
    let isSelectionMode: Bool
    let selectedItems: Set<UUID>
    let syncServiceLastSaveDate: Date
    let storageStatsRefreshTrigger: Int
    let dataService: DataService
    let minColumns: Int
    let maxColumns: Int
    
    let onCategoryChange: () -> Void
    let onSearchQueryChange: (String) -> Void
    let onMenuStateChange: (Bool) -> Void
    let onLoadMore: (Int) -> Void
    let onToggleSelection: (UUID) -> Void
    let onDeleteItem: (ContentItem) -> Void
    let onStorageStatsRefresh: () -> Void
    
    // MARK: - Scroll & Pinch State
    @State private var scrollPosition = ScrollPosition(idType: String.self)
    @State private var isPinching: Bool = false
    @State private var pinchScale: CGFloat = 1.0
    
    var body: some View {
        ScrollView {
            contentStack
                .scrollTargetLayout()
        }
        .id(selectedContentType ?? "all")
        .scrollPosition($scrollPosition)
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .scrollDisabled(isMenuOpen || isSettingsOpen)
        .onChange(of: selectedContentType) {
            onCategoryChange()
        }
        .onChange(of: searchQuery) {
            onSearchQueryChange(searchQuery)
        }
        .onChange(of: isMenuOpen) {
            onMenuStateChange(isMenuOpen)
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y
        } action: { oldValue, newValue in
            if abs(newValue - oldValue) > 5 {
                scrollProgress = newValue > oldValue ? 1.0 : 0.0
            }
        }
        .highPriorityGesture(magnifyGesture)
    }
    
    private var contentStack: some View {
        LazyVStack(spacing: 0) {
            Color.clear.frame(height: 0).id("top")
            
            if filteredItems.isEmpty {
                emptyStateView
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
    
    // MARK: - Magnify Gesture (iOS 18+)
    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                isPinching = true
                let scale = value.magnification
                pinchScale = min(max(scale, 0.98), 1.02)
            }
            .onEnded { value in
                let finalScale = value.magnification
                var newColumns = numberOfColumns
                
                if finalScale > 1.08 {
                    newColumns = numberOfColumns < maxColumns ? numberOfColumns + 1 : minColumns
                } else if finalScale < 0.92 {
                    newColumns = numberOfColumns > minColumns ? numberOfColumns - 1 : maxColumns
                }
                
                if newColumns != numberOfColumns {
                    withAnimation(.snappy(duration: 0.28)) {
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
    
    private var emptyStateView: some View {
        EmptyStateView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
