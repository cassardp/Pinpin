import SwiftUI

struct TimelineGroupedView: View {
    let items: [ContentItem]
    let numberOfColumns: Int
    let dynamicSpacing: CGFloat
    let dynamicCornerRadius: CGFloat
    let isPinching: Bool
    let pinchScale: CGFloat
    let isSelectionMode: Bool
    let selectedItems: Set<UUID>
    let dataService: DataService
    let onLoadMore: (Int) -> Void
    let onToggleSelection: (UUID) -> Void
    let onDeleteItem: (ContentItem) -> Void
    let onStorageStatsRefresh: () -> Void
    
    @StateObject private var userPreferences = UserPreferences.shared
    
    // Grouper les items par jour
    private var groupedByDay: [(date: Date, items: [ContentItem])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: items) { item in
            calendar.startOfDay(for: item.createdAt)
        }
        return grouped.sorted { $0.key > $1.key }.map { (date: $0.key, items: $0.value) }
    }
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 24) {
            // Header avec le titre All
            if userPreferences.showCategoryTitles {
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
            
            ForEach(groupedByDay, id: \.date) { group in
                VStack(alignment: .leading, spacing: 12) {
                    // En-tête de la section avec la date (sauf pour aujourd'hui)
                    if !Calendar.current.isDateInToday(group.date) {
                        HStack(spacing: 12) {
                            Rectangle()
                                .fill(Color(uiColor: .systemGray6))
                                .frame(height: 1)
                            
                            Text(formatDate(group.date))
                                .font(.system(size: 18, design: .serif))
                                .italic()
                                .foregroundColor(.primary)
                                .fixedSize()
                            
                            Rectangle()
                                .fill(Color(uiColor: .systemGray6))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 16)
                    }
                    
                    // Items du jour en grille
                    TimelineDayGrid(
                        items: group.items,
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
                }
                .padding(.top, Calendar.current.isDateInToday(group.date) ? -24 : 0)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .year) {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateFormat = "EEEE, MMMM d" // Ex: "Monday, January 15"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateFormat = "EEEE, MMMM d, yyyy" // Ex: "Monday, January 15, 2024"
            return formatter.string(from: date)
        }
    }
}

// Grille pour les items d'un jour
struct TimelineDayGrid: View {
    let items: [ContentItem]
    let numberOfColumns: Int
    let dynamicSpacing: CGFloat
    let dynamicCornerRadius: CGFloat
    let isPinching: Bool
    let pinchScale: CGFloat
    let isSelectionMode: Bool
    let selectedItems: Set<UUID>
    let dataService: DataService
    let onLoadMore: (Int) -> Void
    let onToggleSelection: (UUID) -> Void
    let onDeleteItem: (ContentItem) -> Void
    let onStorageStatsRefresh: () -> Void
    
    var body: some View {
        PinterestLayoutWrapper(numberOfColumns: numberOfColumns, itemSpacing: dynamicSpacing) {
            ForEach(items, id: \.safeId) { item in
                itemCard(for: item)
            }
        }
        .scaleEffect(isPinching ? pinchScale : 1.0, anchor: .center)
        .animation(.linear(duration: 0.08), value: pinchScale)
        .allowsHitTesting(!isPinching)
    }
    
    @ViewBuilder
    private func itemCard(for item: ContentItem) -> some View {
        if let index = items.firstIndex(of: item) {
            buildCard(for: item)
                .onAppear {
                    onLoadMore(index)
                }
        } else {
            buildCard(for: item)
        }
    }
    
    @ViewBuilder
    private func buildCard(for item: ContentItem) -> some View {
        ContentItemCard(
            item: item,
            cornerRadius: dynamicCornerRadius,
            numberOfColumns: numberOfColumns,
            isSelectionMode: isSelectionMode,
            onSelectionTap: { onToggleSelection(item.safeId) }
        )
        .id(item.safeId)
        .allowsHitTesting(!isPinching)
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: dynamicCornerRadius))
        .contextMenu {
            if !isSelectionMode {
                ContentItemContextMenu(
                    item: item,
                    dataService: dataService,
                    onStorageStatsRefresh: onStorageStatsRefresh,
                    onDeleteRequest: { onDeleteItem(item) }
                )
            }
        }
        .overlay(selectionOverlay(for: item))
    }
    
    @ViewBuilder
    private func selectionOverlay(for item: ContentItem) -> some View {
        if isSelectionMode {
            VStack {
                HStack {
                    Button(action: {
                        onToggleSelection(item.safeId)
                    }) {
                        Image(systemName: selectedItems.contains(item.safeId) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedItems.contains(item.safeId) ? .red : .gray)
                            .font(.system(size: 20))
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
