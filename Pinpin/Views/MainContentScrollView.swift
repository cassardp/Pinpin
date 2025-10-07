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
    let onItemTap: (ContentItem) -> Void
    let heroNamespace: Namespace.ID
    
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
                // Titre unique en haut pour le mode timeline
                if userPreferences.showTimelineView && selectedContentType == nil && userPreferences.showCategoryTitles {
                    categoryTitle
                }
                
                if userPreferences.showTimelineView && selectedContentType == nil {
                    timelineContent
                } else {
                    simpleListContent
                }
                
                storageStats
            }
        }
        .padding(.horizontal, 10)
        .overlay(pinchShield)
    }
    
    // MARK: - Category Title
    private var categoryTitle: some View {
        Text("All")
            .font(.system(size: 24, design: .serif))
            .italic()
            .fontWeight(.thin)
            .foregroundStyle(.primary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 32)
            .padding(.top, 20)
    }
    
    // MARK: - Simple List Content
    private var simpleListContent: some View {
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
            showTitle: true,
            onLoadMore: onLoadMore,
            onToggleSelection: onToggleSelection,
            onDeleteItem: onDeleteItem,
            onStorageStatsRefresh: onStorageStatsRefresh,
            onItemTap: onItemTap,
            heroNamespace: heroNamespace
        )
    }
    
    // MARK: - Timeline Content
    private var timelineContent: some View {
        let groups = groupedByDate(filteredItems)
        // Pré-calculer les offsets pour éviter les recalculs
        let groupOffsets = groups.indices.map { index in
            groups.prefix(index).reduce(0) { $0 + $1.items.count }
        }
        
        return ForEach(Array(groups.enumerated()), id: \.element.date) { groupIndex, group in
            let offset = groupOffsets[groupIndex]
            
            Section {
                ContentGridView(
                    items: group.items,
                    numberOfColumns: numberOfColumns,
                    dynamicSpacing: dynamicSpacing,
                    dynamicCornerRadius: dynamicCornerRadius,
                    isPinching: isPinching,
                    pinchScale: pinchScale,
                    selectedContentType: selectedContentType,
                    isSelectionMode: isSelectionMode,
                    selectedItems: selectedItems,
                    dataService: dataService,
                    showTitle: false,
                    onLoadMore: { itemIndex in
                        // Utiliser l'offset pré-calculé
                        let globalIndex = offset + itemIndex
                        onLoadMore(globalIndex)
                    },
                    onToggleSelection: onToggleSelection,
                    onDeleteItem: onDeleteItem,
                    onStorageStatsRefresh: onStorageStatsRefresh,
                    onItemTap: onItemTap,
                    heroNamespace: heroNamespace
                )
            } header: {
                // Ne pas afficher le séparateur pour le premier groupe
                if groupIndex > 0 {
                    dateSeparator(for: group.date)
                }
            }
        }
    }
    
    // MARK: - Date Separator
    private func dateSeparator(for date: Date) -> some View {
        HStack(spacing: 24) {
            Rectangle()
                .fill(Color(uiColor: .systemGray5).opacity(0.7))
                .frame(height: 1)

            Text(formatDate(date))
                .font(.system(size: 18, design: .serif))
                .italic()
                .foregroundColor(.gray)
                .fixedSize()

            Rectangle()
                .fill(Color(uiColor: .systemGray5).opacity(0.7))
                .frame(height: 1)
        }
        .padding(.horizontal, 4)
        .padding(.top, 48)
        .padding(.bottom, 32)
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
    
    // MARK: - Date Grouping
    private struct DateGroup {
        let date: Date
        let items: [ContentItem]
    }
    
    private func groupedByDate(_ items: [ContentItem]) -> [DateGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: items) { item -> Date in
            calendar.startOfDay(for: item.createdAt)
        }
        
        return grouped
            .map { DateGroup(date: $0.key, items: $0.value) }
            .sorted { $0.date > $1.date }
    }
    
    // MARK: - Date Formatting
    private static let calendar = Calendar.current
    
    private static let currentYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()

    private static let otherYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter
    }()

    private func formatDate(_ date: Date) -> String {
        let now = Date()

        if Self.calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if Self.calendar.isDate(date, equalTo: now, toGranularity: .year) {
            return Self.currentYearFormatter.string(from: date)
        } else {
            return Self.otherYearFormatter.string(from: date)
        }
    }
}
