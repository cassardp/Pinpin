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
    
    // Cache du calendrier
    private let calendar = Calendar.current
    
    // Grouper les items par jour (mémorisé dans l'état)
    @State private var groupedByDay: [(date: Date, items: [ContentItem])] = []
    // Index global par ID pour la pagination (évite O(n^2))
    @State private var indexById: [UUID: Int] = [:]
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 32) {
            // Header avec le titre Timeline ou All
            if userPreferences.showCategoryTitles {
                Text(userPreferences.enableTimelineView ? "Today" : "All")
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
                    if !calendar.isDateInToday(group.date) {
                        HStack(spacing: 24) {
                            Rectangle()
                                .fill(Color(uiColor: .systemGray5).opacity(0.7))
                                .frame(height: 1)
                            
                            Text(formatDate(group.date))
                                .font(.system(size: 18, design: .serif))
                                .italic()
                                .foregroundColor(.gray)
                                .fixedSize()
                            
                            Rectangle()
                                .fill(Color(uiColor: .systemGray5).opacity(0.7))
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
                        globalIndexProvider: { id in indexById[id] },
                        onToggleSelection: onToggleSelection,
                        onDeleteItem: onDeleteItem,
                        onStorageStatsRefresh: onStorageStatsRefresh
                    )
                }
                .padding(.top, calendar.isDateInToday(group.date) ? -24 : 0)
            }
        }
        .transaction { $0.animation = nil }
        .onAppear { recomputeGroupsAndIndex() }
        .onChange(of: items) { _, _ in recomputeGroupsAndIndex() }
    }
    
    // DateFormatters statiques pour éviter la recréation
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
        
        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .year) {
            return Self.currentYearFormatter.string(from: date)
        } else {
            return Self.otherYearFormatter.string(from: date)
        }
    }

    private func recomputeGroupsAndIndex() {
        // Recalcul du groupement par jour
        let grouped = Dictionary(grouping: items) { item in
            calendar.startOfDay(for: item.createdAt)
        }
        let sortedDates = grouped.keys.sorted(by: >)
        groupedByDay = sortedDates.map { date in
            (date: date, items: grouped[date] ?? [])
        }
        // Recalcul de l'index global (id -> index)
        var map: [UUID: Int] = [:]
        for (idx, it) in items.enumerated() {
            map[it.safeId] = idx
        }
        indexById = map
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
    let globalIndexProvider: (UUID) -> Int?
    let onToggleSelection: (UUID) -> Void
    let onDeleteItem: (ContentItem) -> Void
    let onStorageStatsRefresh: () -> Void
    
    var body: some View {
        PinterestLayoutWrapper(numberOfColumns: numberOfColumns, itemSpacing: dynamicSpacing) {
            ForEach(items.indices, id: \.self) { index in
                let item = items[index]
                buildCard(for: item)
                    .id(item.safeId)
                    .onAppear {
                        if let globalIndex = globalIndexProvider(item.safeId) {
                            onLoadMore(globalIndex)
                        } else {
                            onLoadMore(index)
                        }
                    }
            }
        }
        .scaleEffect(isPinching ? pinchScale : 1.0, anchor: .center)
        .animation(.linear(duration: 0.08), value: pinchScale)
        .allowsHitTesting(!isPinching)
        .animation(nil, value: items.count)
        .transaction { $0.animation = nil }
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
