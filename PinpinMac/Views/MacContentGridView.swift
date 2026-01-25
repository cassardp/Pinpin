//
//  MacContentGridView.swift
//  PinpinMac
//
//  Grille de contenu avec layout Pinterest et gestion de sélection
//

import SwiftUI
import SwiftData

struct MacContentGridView: View {
    let filteredItems: [ContentItem]
    let numberOfColumns: Int
    let selectedCategory: String?
    let categoryNames: [String]

    @Bindable var selectionManager: MacSelectionManager

    var onMoveToCategory: (ContentItem, String) -> Void
    var onDeleteItem: (ContentItem) -> Void

    @State private var hoveredItemId: UUID? = nil

    var body: some View {
        ZStack {
            if filteredItems.isEmpty {
                emptyStateView
            } else {
                scrollContent
            }
        }
    }

    // MARK: - Content

    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                MacPinterestLayout(numberOfColumns: numberOfColumns, itemSpacing: 16) {
                    ForEach(filteredItems) { item in
                        contentCard(for: item)
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
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: filteredItems.map(\.id))
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 80)

                StorageStatsView(
                    selectedContentType: selectedCategory,
                    filteredItems: filteredItems
                )
                .padding(.vertical, 24)
                .padding(.bottom, 80)
            }
        }
    }

    private func contentCard(for item: ContentItem) -> some View {
        MacContentCard(
            item: item,
            numberOfColumns: numberOfColumns,
            isHovered: hoveredItemId == item.id,
            isSelectionMode: selectionManager.isSelectionMode,
            isSelected: selectionManager.isSelected(item.id),
            onTap: { },
            onToggleSelection: {
                selectionManager.toggleSelection(for: item.id)
            },
            onOpenURL: { openURL(for: item) }
        )
        .onHover { isHovered in
            if !selectionManager.isSelectionMode {
                withAnimation(.easeInOut(duration: 0.15)) {
                    hoveredItemId = isHovered ? item.id : nil
                }
            }
        }
        .contextMenu {
            if !selectionManager.isSelectionMode {
                contextMenuContent(for: item)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Text("NOTHING YET • START SHARING TO PINPIN!")
                .font(.system(size: 12))
                .foregroundColor(.gray.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func contextMenuContent(for item: ContentItem) -> some View {
        // Share
        if let urlString = item.url,
           let url = URL(string: urlString),
           !urlString.isEmpty,
           !urlString.hasPrefix("file://"),
           !urlString.hasPrefix("images/"),
           !urlString.contains("supabase.co") {

            ShareLink(item: url) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }

        // Move to category
        Menu {
            ForEach(categoryNames, id: \.self) { categoryName in
                if categoryName != item.safeCategoryName {
                    Button(categoryName) {
                        onMoveToCategory(item, categoryName)
                    }
                }
            }
        } label: {
            Label(item.safeCategoryName.capitalized, systemImage: "folder")
        }

        // Search Similar
        MacSimilarSearchMenu(item: item)

        Divider()

        // Delete
        Button(role: .destructive) {
            onDeleteItem(item)
        } label: {
            Label("Delete", systemImage: "trash")
                .foregroundStyle(.red)
        }
    }

    // MARK: - Actions

    private func openURL(for item: ContentItem) {
        guard let urlString = item.url,
              let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }
}
