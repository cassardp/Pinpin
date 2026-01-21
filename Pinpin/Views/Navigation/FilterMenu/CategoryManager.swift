import SwiftUI
import SwiftData

// MARK: - CategoryManager
@Observable
final class CategoryManager {
    // MARK: - Properties
    var categoryToRename: Category?
    var renameText: String = ""
    var isShowingRenameSheet = false
    var isCreatingCategory = false
    var categoryToDelete: Category?
    var isShowingDeleteAlert = false
    var hapticTrigger: Int = 0
    
    private let modelContext: ModelContext
    private let allCategories: [Category]
    private let contentItems: [ContentItem]
    
    // MARK: - Bindings
    var selectedContentType: Binding<String?>
    
    // MARK: - Init
    init(
        modelContext: ModelContext,
        allCategories: [Category],
        contentItems: [ContentItem],
        selectedContentType: Binding<String?>
    ) {
        self.modelContext = modelContext
        self.allCategories = allCategories
        self.contentItems = contentItems
        self.selectedContentType = selectedContentType
    }
    
    // MARK: - Computed Properties
    var availableCategories: [Category] {
        return allCategories.filter { category in
            if category.name == "Misc" {
                return countForType(category.name) > 0
            }
            return true
        }
    }
    
    var processedCategoryName: String {
        renameText.trimmingCharacters(in: .whitespacesAndNewlines).capitalized
    }
    
    // MARK: - Count Methods
    func countForType(_ type: String?) -> Int {
        guard let type = type else { return contentItems.count }
        
        // Pour "Misc", compter aussi les items sans catégorie
        if type == "Misc" {
            return contentItems.filter { $0.category == nil || $0.category?.name == "Misc" }.count
        }
        
        return contentItems.filter { $0.safeCategoryName == type }.count
    }
    

    
    // MARK: - Rename Actions
    func prepareRename(for category: Category) {
        renameText = category.name.capitalized
        categoryToRename = category
        isCreatingCategory = false
        isShowingRenameSheet = true
    }
    
    func prepareCreateCategory() {
        renameText = ""
        categoryToRename = nil
        isCreatingCategory = true
        isShowingRenameSheet = true
    }
    
    func resetRenameState() {
        renameText = ""
        categoryToRename = nil
        isCreatingCategory = false
        isShowingRenameSheet = false
    }
    
    func saveRenamedCategory(_ category: Category) {
        let newName = processedCategoryName
        let oldName = category.name
        
        guard validateCategoryName(newName, excludingId: category.id) else {
            resetRenameState()
            return
        }
        
        category.name = newName
        try? modelContext.save()
        
        if selectedContentType.wrappedValue == oldName {
            selectedContentType.wrappedValue = newName
        }
        
        resetRenameState()
    }
    
    func saveNewCategory() {
        let newName = processedCategoryName
        
        guard validateCategoryName(newName) else {
            resetRenameState()
            return
        }
        
        let newCategory = Category(name: newName)
        modelContext.insert(newCategory)
        try? modelContext.save()
        selectedContentType.wrappedValue = nil // Retourner sur "All" au lieu de sélectionner la catégorie vide
        resetRenameState()
    }
    
    func handleSaveAction() {
        if isCreatingCategory {
            saveNewCategory()
        } else {
            guard let categoryToRename else {
                resetRenameState()
                return
            }
            saveRenamedCategory(categoryToRename)
        }
    }
    
    // MARK: - Delete Actions
    func prepareDelete(for category: Category) {
        categoryToDelete = category
        isShowingDeleteAlert = true
    }
    
    func deleteCategory(_ category: Category) {
        let name = category.name
        
        // Réassigner les items à "Misc" si nécessaire
        if let items = category.contentItems, !items.isEmpty {
            // Trouver ou créer "Misc"
            let miscCategory = allCategories.first(where: { $0.name == "Misc" }) ?? {
                let misc = Category(name: "Misc")
                modelContext.insert(misc)
                return misc
            }()
            
            for item in items {
                item.category = miscCategory
            }
        }
        
        modelContext.delete(category)
        try? modelContext.save()
        
        if selectedContentType.wrappedValue == name {
            selectedContentType.wrappedValue = nil
        }
        
        resetDeleteState()
    }
    
    func resetDeleteState() {
        categoryToDelete = nil
        isShowingDeleteAlert = false
    }
    
    // MARK: - Move Actions
    func moveCategories(from source: IndexSet, to destination: Int) {
        hapticTrigger += 1
        
        // Créer une copie mutable des catégories visibles
        var reorderedCategories = availableCategories
        reorderedCategories.move(fromOffsets: source, toOffset: destination)
        
        // Préparer les updates de sortOrder pour le repository
        var updates: [(category: Category, order: Int32)] = []
        
        // Mettre à jour le sortOrder de toutes les catégories visibles
        for (newIndex, category) in reorderedCategories.enumerated() {
            updates.append((category, Int32(newIndex)))
        }
        
        // Les catégories non visibles gardent leur ordre après les visibles
        let visibleIds = Set(reorderedCategories.map { $0.id })
        let hiddenCategories = allCategories.filter { !visibleIds.contains($0.id) }
        for (offset, category) in hiddenCategories.enumerated() {
            updates.append((category, Int32(reorderedCategories.count + offset)))
        }
        
        // Mettre à jour l'ordre directement
        for (category, newOrder) in updates {
            category.sortOrder = newOrder
        }
        try? modelContext.save()
    }
    
    // MARK: - Validation
    private func validateCategoryName(_ name: String, excludingId: UUID? = nil) -> Bool {
        guard !name.isEmpty else { return false }
        
        return !allCategories.contains { category in
            category.name.caseInsensitiveCompare(name) == .orderedSame &&
            category.id != excludingId
        }
    }
}
