//
//  MacMainView.swift
//  PinpinMac
//
//  Vue principale de l'application Mac avec grille masonry
//

import SwiftUI
import SwiftData

struct MacMainView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ContentItem.createdAt, order: .reverse)
    private var allContentItems: [ContentItem]

    @Query(sort: \Category.sortOrder, order: .forward)
    private var allCategories: [Category]

    // Managers
    @State private var categoryManager = CategoryManager()
    @State private var selectionManager = MacSelectionManager()

    // Column layout
    @State private var contentWidth: CGFloat = 0
    @State private var columnOffset: Int = 0

    // UI State
    @State private var showAddNote: Bool = false
    @State private var showDeleteSelectedAlert: Bool = false
    @State private var searchQuery: String = ""
    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly

    // MARK: - Computed

    private var numberOfColumns: Int {
        let baseColumns = AppConstants.optimalColumns(for: contentWidth)
        let adjusted = baseColumns + columnOffset
        return max(AppConstants.minColumns, min(AppConstants.maxColumns, adjusted))
    }

    private var filteredItems: [ContentItem] {
        var items = allContentItems

        // Filter by category
        if !categoryManager.isAllPinsSelected {
            items = items.filter { $0.safeCategoryName == categoryManager.selectedCategory }
        }

        // Filter by search
        if !searchQuery.isEmpty {
            items = items.filter { item in
                item.title.localizedCaseInsensitiveContains(searchQuery) ||
                (item.itemDescription?.localizedCaseInsensitiveContains(searchQuery) ?? false) ||
                (item.url?.localizedCaseInsensitiveContains(searchQuery) ?? false)
            }
        }

        return items
    }

    private var visibleCategories: [Category] {
        categoryManager.visibleCategories(from: allCategories) { name in
            allContentItems.filter { $0.safeCategoryName == name }.count
        }
    }

    private var categoryNames: [String] {
        visibleCategories.map { $0.name }
    }

    private var allItemIds: [UUID] {
        filteredItems.map { $0.id }
    }

    // MARK: - Body

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            MacSidebarView(
                categoryManager: categoryManager,
                isSidebarVisible: columnVisibility != .detailOnly
            )
        } detail: {
            contentView
        }
        .navigationSplitViewStyle(.balanced)
        .floatingPanel(isPresented: $showAddNote) {
            addNoteSheet
        }
        .floatingPanel(isPresented: $categoryManager.showRenameSheet) {
            renameCategorySheet
        }
        .alert("Delete Category", isPresented: $categoryManager.showDeleteAlert, presenting: categoryManager.categoryToDelete) { category in
            deleteCategoryAlert(for: category)
        } message: { category in
            Text("Are you sure you want to delete \"\(category.name)\"? The pins in this category will not be deleted.")
        }
        .alert("Delete Selected Items", isPresented: $showDeleteSelectedAlert) {
            deleteSelectedAlert
        } message: {
            Text("Are you sure you want to delete \(selectionManager.selectedCount) item\(selectionManager.selectedCount > 1 ? "s" : "")?")
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        GeometryReader { geometry in
            MacContentGridView(
                filteredItems: filteredItems,
                numberOfColumns: numberOfColumns,
                selectedCategory: categoryManager.isAllPinsSelected ? nil : categoryManager.selectedCategory,
                categoryNames: categoryNames,
                selectionManager: selectionManager,
                onMoveToCategory: moveToCategory,
                onDeleteItem: deleteItem
            )
            .searchable(text: $searchQuery, prompt: "Search...")
            .toolbar { toolbarContent }
            .gesture(magnifyGesture)
            .onChange(of: geometry.size.width) { _, newWidth in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    contentWidth = newWidth
                }
            }
            .onAppear {
                contentWidth = geometry.size.width
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if selectionManager.isSelectionMode {
            MacSelectionModeToolbar(
                numberOfColumns: numberOfColumns,
                hasSelection: selectionManager.hasSelection,
                selectedCount: selectionManager.selectedCount,
                categoryNames: categoryNames,
                onColumnDecrease: decreaseColumns,
                onColumnIncrease: increaseColumns,
                onSelectAll: { selectionManager.selectAll(items: allItemIds) },
                onMoveToCategory: moveSelectedToCategory,
                onDelete: { showDeleteSelectedAlert = true },
                onClose: { selectionManager.toggleSelectionMode() }
            )
        } else {
            MacNormalModeToolbar(
                numberOfColumns: numberOfColumns,
                onColumnDecrease: decreaseColumns,
                onColumnIncrease: increaseColumns,
                onSelect: { selectionManager.toggleSelectionMode() },
                onAddNote: { showAddNote = true }
            )
        }
    }

    // MARK: - Gestures

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onEnded { value in
                let scale = value.magnification
                withAnimation(.spring(response: 0.3)) {
                    if scale > 1.1 && numberOfColumns > AppConstants.minColumns {
                        columnOffset -= 1
                    } else if scale < 0.9 && numberOfColumns < AppConstants.maxColumns {
                        columnOffset += 1
                    }
                }
            }
    }

    // MARK: - Sheets & Alerts

    private var addNoteSheet: some View {
        TextEditSheet(
            item: nil,
            targetCategory: allCategories.first(where: { $0.name == categoryManager.selectedCategory })
        )
    }

    @ViewBuilder
    private var renameCategorySheet: some View {
        if let category = categoryManager.categoryToRename {
            RenameCategorySheet(
                name: $categoryManager.renameCategoryName,
                onCancel: {
                    categoryManager.cancelRename()
                },
                onSave: {
                    if categoryManager.isCreatingCategory {
                        categoryManager.confirmCreate(in: modelContext, totalCount: allCategories.count)
                    } else {
                        categoryManager.confirmRename(category, in: modelContext)
                    }
                }
            )
        }
    }

    @ViewBuilder
    private func deleteCategoryAlert(for category: Category) -> some View {
        Button("Cancel", role: .cancel) {
            categoryManager.cancelDelete()
        }
        Button("Delete", role: .destructive) {
            categoryManager.confirmDelete(in: modelContext)
        }
    }

    @ViewBuilder
    private var deleteSelectedAlert: some View {
        Button("Cancel", role: .cancel) { }
        Button("Delete", role: .destructive) {
            deleteSelectedItems()
        }
    }

    // MARK: - Actions

    private func decreaseColumns() {
        guard numberOfColumns > AppConstants.minColumns else { return }
        withAnimation(.spring(response: 0.3)) {
            columnOffset -= 1
        }
    }

    private func increaseColumns() {
        guard numberOfColumns < AppConstants.maxColumns else { return }
        withAnimation(.spring(response: 0.3)) {
            columnOffset += 1
        }
    }

    private func moveToCategory(item: ContentItem, categoryName: String) {
        guard let category = allCategories.first(where: { $0.name == categoryName }) else { return }
        item.category = category
        try? modelContext.save()
    }

    private func deleteItem(_ item: ContentItem) {
        withAnimation {
            modelContext.delete(item)
            try? modelContext.save()
        }
    }

    private func moveSelectedToCategory(_ categoryName: String) {
        guard let targetCategory = allCategories.first(where: { $0.name == categoryName }) else { return }

        for itemId in selectionManager.selectedItems {
            if let item = allContentItems.first(where: { $0.id == itemId }) {
                item.category = targetCategory
            }
        }

        try? modelContext.save()
        selectionManager.deselectAll()
    }

    private func deleteSelectedItems() {
        withAnimation {
            for itemId in selectionManager.selectedItems {
                if let item = allContentItems.first(where: { $0.id == itemId }) {
                    modelContext.delete(item)
                }
            }
            try? modelContext.save()
            selectionManager.deselectAll()
        }
    }
}
