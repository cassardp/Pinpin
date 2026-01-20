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
    
    // Constante pour "All Pins"
    private static let allPinsValue = "___ALL_PINS___"
    
    @Query(sort: \ContentItem.createdAt, order: .reverse)
    private var allContentItems: [ContentItem]
    
    @Query(sort: \Category.sortOrder, order: .forward)
    private var allCategories: [Category]
    
    @State private var selectedCategory: String = MacMainView.allPinsValue
    @State private var numberOfColumns: Int = 4

    @State private var showSettings: Bool = false
    @State private var showAbout: Bool = false
    @State private var showAddNote: Bool = false
    @State private var hoveredItemId: UUID? = nil
    
    // Category editing state
    @State private var categoryToRename: Category? = nil
    @State private var categoryToDelete: Category? = nil
    @State private var showDeleteCategoryAlert: Bool = false
    @State private var showDeleteSelectedAlert: Bool = false
    @State private var renameCategoryName: String = ""
    @State private var isCreatingCategory: Bool = false
    
    // Selection Manager
    @State private var selectionManager = MacSelectionManager()
    
    private var isAllPinsSelected: Bool {
        selectedCategory == Self.allPinsValue
    }
    
    private var filteredItems: [ContentItem] {
        var items = allContentItems
        
        // Filtrer par catégorie (sauf si "All Pins" est sélectionné)
        if !isAllPinsSelected {
            items = items.filter { $0.safeCategoryName == selectedCategory }
        }
        
        // Filtrer par recherche
        if !searchQueryState.isEmpty {
            items = items.filter { item in
                item.title.localizedCaseInsensitiveContains(searchQueryState) ||
                (item.itemDescription?.localizedCaseInsensitiveContains(searchQueryState) ?? false) ||
                (item.url?.localizedCaseInsensitiveContains(searchQueryState) ?? false)
            }
        }
        
        return items
    }
    
    private var categoryNames: [String] {
        visibleCategories.map { $0.name }
    }
    
    // Catégories visibles (masque "Misc" si elle est vide)
    private var visibleCategories: [Category] {
        return allCategories.filter { category in
            if category.name == "Misc" {
                return countForCategory(category.name) > 0
            }
            return true
        }
    }
    
    @State private var searchQueryState: String = ""
    
    @State private var columnVisibilityState: NavigationSplitViewVisibility = .automatic
    
    private var allItemIds: [UUID] {
        filteredItems.map { $0.id }
    }
    
    private var isSidebarVisible: Bool {
        columnVisibilityState != .detailOnly
    }

    var body: some View {
        mainView
            .toolbar {
                toolbarContent
            }
            .searchable(text: $searchQueryState, prompt: "Search...")
            .sheet(isPresented: $showSettings) {
                MacSettingsView()
            }
            .sheet(isPresented: $showAbout) {
                InfoSheet()
            }
            .sheet(isPresented: $showAddNote) {
                addNoteSheet
            }
            .sheet(item: $categoryToRename) { category in
                renameCategorySheet(for: category)
            }
            .alert("Delete Category", isPresented: $showDeleteCategoryAlert, presenting: categoryToDelete) { category in
                deleteCategoryAlert(for: category)
            } message: { category in
                Text("Are you sure you want to delete \"\(category.name)\"? The pins in this category will not be deleted.")
            }
            .alert("Delete Selected Items", isPresented: $showDeleteSelectedAlert) {
                deleteSelectedAlert
            } message: {
                deleteSelectedMessage
            }
    }
    
    private var mainView: some View {
        NavigationSplitView(columnVisibility: $columnVisibilityState) {
            sidebarView
        } detail: {
            mainContentView
        }
        .navigationSplitViewStyle(.balanced)
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        MacToolbarView(
            selectionManager: selectionManager,
            categoryNames: categoryNames,
            allItemIds: allItemIds,
            onMoveToCategory: moveSelectedItemsToCategory,
            onDeleteSelected: handleDeleteSelected
        )
    }
    
    private var addNoteSheet: some View {
        TextEditSheet(
            item: nil,
            targetCategory: allCategories.first(where: { $0.name == selectedCategory })
        )
    }
    
    private func renameCategorySheet(for category: Category) -> some View {
        RenameCategorySheet(
            name: $renameCategoryName,
            onCancel: {
                categoryToRename = nil
                renameCategoryName = ""
                isCreatingCategory = false
            },
            onSave: {
                if isCreatingCategory {
                    createCategory()
                } else {
                    renameCategory(category)
                }
            }
        )
    }
    
    @ViewBuilder
    private func deleteCategoryAlert(for category: Category) -> some View {
        Button("Cancel", role: .cancel) {
            categoryToDelete = nil
        }
        Button("Delete", role: .destructive) {
            deleteCategory(category)
        }
    }
    
    @ViewBuilder
    private var deleteSelectedAlert: some View {
        Button("Cancel", role: .cancel) { }
        Button("Delete", role: .destructive) {
            deleteSelectedItems()
        }
    }
    
    private var deleteSelectedMessage: some View {
        Text("Are you sure you want to delete \(selectionManager.selectedCount) item\(selectionManager.selectedCount > 1 ? "s" : "")?")
    }
    
    // MARK: - Sidebar
    
    private var sidebarView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            List {
                // Option "All"
                MacCategoryRow(
                    title: "All",
                    isSelected: isAllPinsSelected,
                    isEmpty: allContentItems.isEmpty
                ) {
                    withAnimation(.easeInOut(duration: 0.28)) {
                        selectedCategory = Self.allPinsValue
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
                
                // Catégories
                ForEach(visibleCategories) { category in
                    MacCategoryRow(
                        title: category.name,
                        isSelected: selectedCategory == category.name,
                        isEmpty: countForCategory(category.name) == 0,
                        action: {
                            withAnimation(.easeInOut(duration: 0.28)) {
                                selectedCategory = category.name
                            }
                        },
                        onRename: {
                            renameCategoryName = category.name
                            categoryToRename = category
                        },
                        onDelete: {
                            categoryToDelete = category
                            showDeleteCategoryAlert = true
                        }
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .padding(.horizontal, 24)
            
            Spacer()
            
            // MARK: - Bottom Menu
            HStack {
                MacSidebarMenu(
                    onAddNote: handleAddNote,
                    onAddCategory: prepareCreateCategory,
                    onEditCategories: handleEditCategories,
                    onSettings: handleSettings,
                    onAbout: handleAbout
                )
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .frame(minWidth: 200, maxWidth: 280)
        .frame(maxHeight: .infinity)
    }
    
    private func countForCategory(_ category: String) -> Int {
        allContentItems.filter { $0.safeCategoryName == category }.count
    }
    
    // MARK: - Main Content
    
    private var mainContentView: some View {
        ZStack {
            if filteredItems.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        MacPinterestLayout(numberOfColumns: numberOfColumns, itemSpacing: 16) {
                            ForEach(filteredItems) { item in
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
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, columnVisibilityState == .detailOnly ? 64 : 24)
                        .padding(.bottom, 80) // Space for stats
                        
                        // Stats at bottom of list
                        if !filteredItems.isEmpty {
                            StorageStatsView(
                                selectedContentType: isAllPinsSelected ? nil : selectedCategory,
                                filteredItems: filteredItems
                            )
                            .padding(.vertical, 24)
                            .padding(.bottom, 80) // Supplementaire pour l'overlay
                        }
                    }
                }
                .ignoresSafeArea(edges: .top)
            }
        }
        .background(.ultraThinMaterial)
        .gesture(magnifyGesture)
    }
    
    // MARK: - Gestures
    
    @State private var pinchScale: CGFloat = 1.0
    
    private var magnifyGesture: some Gesture {
        MagnifyGesture()
             .onChanged { value in
                 // Optional: Interactive scale effect
             }
             .onEnded { value in
                 let scale = value.magnification
                 withAnimation(.spring(response: 0.3)) {
                     if scale > 1.1 {
                         // Zoom In -> Fewer columns
                         if numberOfColumns > 3 {
                             numberOfColumns -= 1
                         }
                     } else if scale < 0.9 {
                         // Zoom Out -> More columns
                         if numberOfColumns < 6 {
                             numberOfColumns += 1
                         }
                     }
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
        // 1. Share
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
        
        // 2. Category (Move to...)
        Menu {
            ForEach(categoryNames, id: \.self) { categoryName in
                if categoryName != item.safeCategoryName {
                    Button(categoryName) {
                        moveToCategory(item: item, categoryName: categoryName)
                    }
                }
            }
        } label: {
            Label(item.safeCategoryName.capitalized, systemImage: "folder")
        }

        // 3. Search Similar
        MacSimilarSearchMenu(item: item)
        
        Divider()
        
        // 4. Delete
        Button(role: .destructive) {
            deleteItem(item)
        } label: {
            Label("Delete", systemImage: "trash")
                .foregroundStyle(.red)
        }
    }
    
    // MARK: - Actions
    
    private func handleAddNote() {
        showAddNote = true
    }
    
    private func handleSettings() {
        showSettings = true
    }
    
    private func handleAbout() {
        showAbout = true
    }
    
    private func handleEditCategories() {
        // TODO: Implémenter le réordonnancement des catégories
        // Pour l'instant, cette action est un placeholder
    }
    
    private func handleDeleteSelected() {
        showDeleteSelectedAlert = true
    }
    
    private func openURL(for item: ContentItem) {
        guard let urlString = item.url,
              let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
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
    
    // MARK: - Category Management
    
    private func prepareCreateCategory() {
        renameCategoryName = ""
        isCreatingCategory = true
        categoryToRename = Category(name: "New Category", sortOrder: Int32(allCategories.count))
    }
    
    private func createCategory() {
        let trimmedName = renameCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let newCategory = Category(
            name: trimmedName,
            sortOrder: Int32(allCategories.count)
        )
        
        modelContext.insert(newCategory)
        try? modelContext.save()
        
        categoryToRename = nil
        renameCategoryName = ""
        isCreatingCategory = false
    }
    
    private func renameCategory(_ category: Category) {
        let trimmedName = renameCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // Update selected category if it was renamed
        if selectedCategory == category.name {
            selectedCategory = trimmedName
        }
        
        category.name = trimmedName
        category.updatedAt = Date()
        try? modelContext.save()
        
        categoryToRename = nil
        renameCategoryName = ""
        isCreatingCategory = false
    }
    
    private func deleteCategory(_ category: Category) {
        // If the deleted category was selected, switch to All Pins
        if selectedCategory == category.name {
            selectedCategory = Self.allPinsValue
        }
        
        withAnimation {
            modelContext.delete(category)
            try? modelContext.save()
        }
        
        categoryToDelete = nil
    }
    
    // MARK: - Selection Management
    
    private func moveSelectedItemsToCategory(_ categoryName: String) {
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

