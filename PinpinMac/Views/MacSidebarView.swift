//
//  MacSidebarView.swift
//  PinpinMac
//
//  Sidebar avec liste des catégories et drag & drop pour réordonnancement
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct MacSidebarView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Category.sortOrder, order: .forward)
    private var allCategories: [Category]

    @Query(sort: \ContentItem.createdAt, order: .reverse)
    private var allContentItems: [ContentItem]

    @Bindable var categoryManager: CategoryManager
    let isSidebarVisible: Bool

    var body: some View {
        sidebarList
            .toolbar {
                if isSidebarVisible {
                    ToolbarItem(placement: .primaryAction) {
                        toolbarButton
                    }
                }
            }
    }

    // MARK: - Sidebar List

    private var sidebarList: some View {
        List {
            // "All" option (non-draggable)
            MacCategoryRow(
                title: "All",
                isSelected: categoryManager.isAllPinsSelected,
                isEmpty: allContentItems.isEmpty
            ) {
                withAnimation(.easeInOut(duration: 0.28)) {
                    categoryManager.selectAllPins()
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))

            // Categories with drag & drop reordering
            ForEach(visibleCategories, id: \.name) { category in
                categoryRow(for: category)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .padding(.horizontal, 12)
    }

    private func categoryRow(for category: Category) -> some View {
        MacCategoryRow(
            title: category.name,
            isSelected: categoryManager.selectedCategory == category.name,
            isEmpty: countForCategory(category.name) == 0,
            action: {
                withAnimation(.easeInOut(duration: 0.28)) {
                    categoryManager.selectCategory(category.name)
                }
            },
            onRename: {
                categoryManager.prepareRename(category)
            },
            onDelete: {
                categoryManager.prepareDelete(category)
            },
            canDelete: category.name != "Misc",
            isEditing: categoryManager.isEditingCategories
        )
        .tag(category.name)
        .onDrag {
            guard categoryManager.isEditingCategories else { return NSItemProvider() }
            categoryManager.draggingItem = category
            return NSItemProvider(object: category.name as NSString)
        }
        .onDrop(of: [UTType.text], delegate: CategoryDropDelegate(
            item: category,
            visibleCategories: visibleCategories,
            draggingItem: $categoryManager.draggingItem,
            onMove: { from, to in
                withAnimation {
                    categoryManager.moveCategories(
                        from: from,
                        to: to,
                        visibleCategories: visibleCategories,
                        allCategories: allCategories,
                        in: modelContext
                    )
                }
            }
        ))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
    }

    // MARK: - Toolbar

    @ViewBuilder
    private var toolbarButton: some View {
        if categoryManager.isEditingCategories {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    categoryManager.exitEditMode()
                }
            } label: {
                Label("Done", systemImage: "checkmark")
            }
        } else {
            Menu {
                Button("Add Category", systemImage: "plus") {
                    categoryManager.prepareCreate(totalCount: allCategories.count)
                }
                Button("Edit Categories", systemImage: "pencil") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        categoryManager.toggleEditMode()
                    }
                }
            } label: {
                Label("Options", systemImage: "ellipsis")
            }
            .menuIndicator(.hidden)
        }
    }

    // MARK: - Helpers

    private var visibleCategories: [Category] {
        categoryManager.visibleCategories(from: allCategories) { name in
            countForCategory(name)
        }
    }

    private func countForCategory(_ name: String) -> Int {
        allContentItems.filter { $0.safeCategoryName == name }.count
    }
}
