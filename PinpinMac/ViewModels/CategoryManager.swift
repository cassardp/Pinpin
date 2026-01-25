//
//  CategoryManager.swift
//  PinpinMac
//
//  Gère la sélection et les opérations CRUD sur les catégories
//

import SwiftUI
import SwiftData

@Observable
@MainActor
final class CategoryManager {
    // Constante pour "All Pins"
    static let allPinsValue = "___ALL_PINS___"

    // MARK: - State

    var selectedCategory: String = CategoryManager.allPinsValue
    var categoryToRename: Category? = nil
    var categoryToDelete: Category? = nil
    var renameCategoryName: String = ""
    var isCreatingCategory: Bool = false
    var isEditingCategories: Bool = false
    var draggingItem: Category? = nil

    // Sheet/Alert visibility
    var showRenameSheet: Bool = false
    var showDeleteAlert: Bool = false

    // MARK: - Computed

    var isAllPinsSelected: Bool {
        selectedCategory == Self.allPinsValue
    }

    // MARK: - Selection

    func selectCategory(_ name: String) {
        selectedCategory = name
    }

    func selectAllPins() {
        selectedCategory = Self.allPinsValue
    }

    // MARK: - Filtering

    func visibleCategories(from allCategories: [Category], countFor: (String) -> Int) -> [Category] {
        allCategories.filter { category in
            if category.name == "Misc" {
                return countFor(category.name) > 0
            }
            return true
        }
    }

    func categoryNames(from visibleCategories: [Category]) -> [String] {
        visibleCategories.map { $0.name }
    }

    // MARK: - Create

    func prepareCreate(totalCount: Int) {
        renameCategoryName = ""
        isCreatingCategory = true
        categoryToRename = Category(name: "New Category", sortOrder: Int32(totalCount))
        showRenameSheet = true
    }

    func confirmCreate(in context: ModelContext, totalCount: Int) {
        let trimmedName = renameCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let newCategory = Category(
            name: trimmedName,
            sortOrder: Int32(totalCount)
        )

        context.insert(newCategory)
        try? context.save()

        resetEditState()
    }

    // MARK: - Rename

    func prepareRename(_ category: Category) {
        renameCategoryName = category.name
        categoryToRename = category
        isCreatingCategory = false
        showRenameSheet = true
    }

    func confirmRename(_ category: Category, in context: ModelContext) {
        let trimmedName = renameCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        // Update selected category if it was renamed
        if selectedCategory == category.name {
            selectedCategory = trimmedName
        }

        category.name = trimmedName
        category.updatedAt = Date()
        try? context.save()

        resetEditState()
    }

    // MARK: - Delete

    func prepareDelete(_ category: Category) {
        categoryToDelete = category
        showDeleteAlert = true
    }

    func confirmDelete(in context: ModelContext) {
        guard let category = categoryToDelete else { return }

        // If the deleted category was selected, switch to All Pins
        if selectedCategory == category.name {
            selectedCategory = Self.allPinsValue
        }

        context.delete(category)
        try? context.save()

        categoryToDelete = nil
    }

    func cancelDelete() {
        categoryToDelete = nil
    }

    // MARK: - Reorder

    func moveCategories(
        from source: IndexSet,
        to destination: Int,
        visibleCategories: [Category],
        allCategories: [Category],
        in context: ModelContext
    ) {
        var reordered = visibleCategories
        reordered.move(fromOffsets: source, toOffset: destination)

        // Update sortOrder for visible categories
        for (index, category) in reordered.enumerated() {
            category.sortOrder = Int32(index)
        }

        // Hidden categories keep their order after visible ones
        let visibleIds = Set(reordered.map { $0.id })
        let hiddenCategories = allCategories.filter { !visibleIds.contains($0.id) }
        for (offset, category) in hiddenCategories.enumerated() {
            category.sortOrder = Int32(reordered.count + offset)
        }

        try? context.save()
    }

    // MARK: - Edit Mode

    func toggleEditMode() {
        isEditingCategories.toggle()
    }

    func exitEditMode() {
        isEditingCategories = false
    }

    // MARK: - Private

    private func resetEditState() {
        categoryToRename = nil
        renameCategoryName = ""
        isCreatingCategory = false
        showRenameSheet = false
    }

    func cancelRename() {
        resetEditState()
    }
}
