import SwiftUI

struct ContentGridView: View {
    let items: [ContentItem]
    let numberOfColumns: Int
    let dynamicSpacing: CGFloat
    let dynamicCornerRadius: CGFloat
    let isPinching: Bool
    let pinchScale: CGFloat
    let selectedContentType: String?
    let isSelectionMode: Bool
    let selectedItems: Set<UUID>
    let dataService: DataService
    let onLoadMore: (Int) -> Void
    let onToggleSelection: (UUID) -> Void
    let onDeleteItem: (ContentItem) -> Void
    let onStorageStatsRefresh: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            PinterestLayoutWrapper(numberOfColumns: numberOfColumns, itemSpacing: dynamicSpacing) {
                ForEach(items, id: \.safeId) { item in
                    itemCard(for: item)
                }
            }
        }
        .id(selectedContentType ?? "all")
        .scaleEffect(isPinching ? pinchScale : 1.0, anchor: .center)
        .animation(.linear(duration: 0.08), value: pinchScale)
        .allowsHitTesting(!isPinching)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: selectedContentType)
    }
    
    @ViewBuilder
    private func itemCard(for item: ContentItem) -> some View {
        if let index = items.firstIndex(of: item) {
            buildCard(for: item)
                .onAppear {
                    onLoadMore(index)
                    if item == items.last {
                        _ = dataService.loadMoreContentItems()
                    }
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
        .onDrag { NSItemProvider(object: item.safeId.uuidString as NSString) }
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
        .transition(.opacity)
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
