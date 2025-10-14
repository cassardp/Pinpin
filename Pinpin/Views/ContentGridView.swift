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
    let onItemTap: (ContentItem) -> Void
    let heroNamespace: Namespace.ID

    private let userPreferences = UserPreferences.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header avec le nom de la catégorie
            if showTitle && userPreferences.showCategoryTitles {
                Text(selectedContentType ?? "All")
                    .font(.system(size: 24, design: .serif))
                    .italic()
                    .fontWeight(.thin)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 32)
                    .padding(.top, 20)
            }

            PinterestLayoutWrapper(numberOfColumns: numberOfColumns, itemSpacing: dynamicSpacing) {
                ForEach(items.indices, id: \.self) { index in
                    buildCard(for: items[index])
                }
            }
            .id(selectedContentType ?? "all")
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
            onSelectionTap: { onToggleSelection(item.safeId) },
            onItemTap: { onItemTap(item) },
            heroNamespace: heroNamespace
        )
        .id(item.safeId)
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
        // Pas de transition pour garder le scroll fluide
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
