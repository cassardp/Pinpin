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
    let showTitle: Bool
    let onToggleSelection: (UUID) -> Void
    let onDeleteItem: (ContentItem) -> Void
    let onStorageStatsRefresh: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            PinterestLayoutWrapper(numberOfColumns: numberOfColumns, itemSpacing: dynamicSpacing) {
                ForEach(items) { item in
                    buildCard(for: item)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.85, anchor: .center)
                                    .combined(with: .opacity),
                                removal: .scale(scale: 0.85, anchor: .center)
                                    .combined(with: .opacity)
                            )
                        )
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: items.map(\.id))
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: numberOfColumns)
        }
        .scaleEffect(isPinching ? pinchScale : 1.0, anchor: .center)
        .animation(.linear(duration: 0.08), value: pinchScale)
        .allowsHitTesting(!isPinching)
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
        .allowsHitTesting(!isPinching)
        .onDrag { NSItemProvider(object: item.safeId.uuidString as NSString) }
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: dynamicCornerRadius))
        .contextMenu {
            if !isSelectionMode {
                ContentItemContextMenu(
                    item: item,
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
            let isSelected = selectedItems.contains(item.safeId)
            VStack {
                HStack {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            onToggleSelection(item.safeId)
                        }
                    }) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isSelected ? .red : .gray)
                            .font(.system(size: 22))
                            .scaleEffect(isSelected ? 1.0 : 0.9)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                    }
                    .padding(8)
                    .contentTransition(.symbolEffect(.replace))

                    Spacer()
                }
                Spacer()
            }
        }
    }
}
