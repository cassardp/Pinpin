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
    
    private var searchQuery: String = ""
    
    @State private var selectedCategory: String = MacMainView.allPinsValue
    @State private var numberOfColumns: Int = 5

    @State private var showSettings: Bool = false
    @State private var hoveredItemId: UUID? = nil
    
    // Category editing state
    @State private var categoryToRename: Category? = nil
    @State private var categoryToDelete: Category? = nil
    @State private var showDeleteCategoryAlert: Bool = false
    @State private var renameCategoryName: String = ""
    
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
        if !searchQuery.isEmpty {
            items = items.filter { item in
                item.title.localizedCaseInsensitiveContains(searchQuery) ||
                (item.itemDescription?.localizedCaseInsensitiveContains(searchQuery) ?? false) ||
                (item.url?.localizedCaseInsensitiveContains(searchQuery) ?? false)
            }
        }
        
        return items
    }
    
    private var categoryNames: [String] {
        visibleCategories.map { $0.name }
    }
    
    // Catégories visibles (toutes les catégories, comme sur iOS)
    private var visibleCategories: [Category] {
        return allCategories
    }
    
    @State private var searchQueryState: String = ""
    
    var body: some View {
        NavigationSplitView {
            // Sidebar avec catégories
            sidebarView
        } detail: {
            // Vue principale avec grille
            mainContentView
        }
        .navigationSplitViewStyle(.balanced)

        .sheet(item: $categoryToRename) { category in
            MacRenameCategorySheet(
                name: $renameCategoryName,
                isEditing: true,
                onCancel: {
                    categoryToRename = nil
                    renameCategoryName = ""
                },
                onSave: {
                    renameCategory(category)
                }
            )
        }
        .alert("Delete Category", isPresented: $showDeleteCategoryAlert, presenting: categoryToDelete) { category in
            Button("Cancel", role: .cancel) {
                categoryToDelete = nil
            }
            Button("Delete", role: .destructive) {
                deleteCategory(category)
            }
        } message: { category in
            Text("Are you sure you want to delete \"\(category.name)\"? The pins in this category will not be deleted.")
        }
    }
    
    // MARK: - Sidebar
    
    private var sidebarView: some View {
        VStack {
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
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
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
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
            ScrollView {
                VStack(spacing: 0) {
                    MacPinterestLayout(numberOfColumns: numberOfColumns, itemSpacing: 16) {
                        ForEach(filteredItems) { item in
                            MacContentCard(
                                item: item,
                                numberOfColumns: numberOfColumns,
                                isHovered: hoveredItemId == item.id,
                                onTap: { },
                                onOpenURL: { openURL(for: item) }
                            )
                            .onHover { isHovered in
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    hoveredItemId = isHovered ? item.id : nil
                                }
                            }
                            .contextMenu {
                                contextMenuContent(for: item)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 80) // Space for overlay
                    
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
            
            // Search Overlay
            VStack {
                Spacer()
                searchOverlay
            }
        }
        .background(.ultraThinMaterial)
        .gesture(magnifyGesture)
    }
    
    // MARK: - Search Overlay
    
    private var searchOverlay: some View {
        HStack(spacing: 0) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.leading, 12)
            
            TextField("Search...", text: Binding(
                get: { searchQueryState },
                set: { newValue in
                    withAnimation(.easeInOut(duration: 0.28)) {
                        searchQueryState = newValue
                    }
                }
            ))
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .padding(.horizontal, 8)
                .frame(height: 36)
            
            if !searchQueryState.isEmpty {
                Button {
                    searchQueryState = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 12)
            }
        }
        .frame(width: 300, height: 44)
        .background(
            Capsule()
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
        )
        .padding(.bottom, 24)
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
        EmptyStateView()
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
}

