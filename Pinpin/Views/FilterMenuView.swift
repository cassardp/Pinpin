//
//  FilterMenuView.swift
//  Pinpin
//
//  Menu latéral de filtrage par type de contenu
//

import SwiftUI
import SwiftData

struct FilterMenuView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ContentItem.createdAt, order: .reverse)
    private var contentItems: [ContentItem]

    @Query(sort: \Category.sortOrder, order: .forward)
    private var allCategories: [Category]

    private let userPreferences = UserPreferences.shared
    @Binding var selectedContentType: String?
    @Binding var isMenuOpen: Bool
    var isMenuDragging: Bool
    var onOpenAbout: () -> Void
    var onOpenSettings: () -> Void
    @State private var isEditing = false
    @State private var categoryToRename: Category?
    @State private var renameText: String = ""
    @State private var isShowingRenameSheet = false
    @State private var isCreatingCategory = false
    @State private var categoryToDelete: Category?
    @State private var isShowingDeleteAlert = false
    @FocusState private var isTextFieldFocused: Bool
    @State private var hapticTrigger: Int = 0
    
    // Récupère toutes les catégories directement depuis SwiftData (ordre natif via sortOrder)
    // Masque "Misc" si elle est vide
    private var availableCategories: [Category] {
        return allCategories.filter { category in
            if category.name == "Misc" {
                return countForType(category.name) > 0
            }
            return true
        }
    }
    
    // Compte les items par type
    private func countForType(_ type: String?) -> Int {
        guard let type = type else { return contentItems.count }
        
        // Pour "Misc", compter aussi les items sans catégorie
        if type == "Misc" {
            return contentItems.filter { $0.category == nil || $0.category?.name == "Misc" }.count
        }
        
        return contentItems.filter { $0.safeCategoryName == type }.count
    }
    
    // Méthode pour déplacer les catégories (fonctionnalité native SwiftUI)
    private func moveCategories(from source: IndexSet, to destination: Int) {
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
    
    var body: some View {
        let backgroundView = Color(UIColor.systemBackground)
            .onTapGesture {
                isTextFieldFocused = false
            }

        return ZStack {
            backgroundView

            // Liste centrée verticalement avec dégradés de fondu
            ZStack {
                ScrollViewReader { proxy in
                    List {

                    // Option "Tout"
                    CategoryListRow(
                        isSelected: selectedContentType == nil,
                        title: "All",
                        isEmpty: contentItems.isEmpty,
                        isEditing: false,
                        action: { selectedContentType = nil }
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    
                    // Types dynamiques avec réorganisation native
                    ForEach(availableCategories, id: \.id) { category in
                        CategoryListRow(
                            isSelected: selectedContentType == category.name,
                            title: category.name.capitalized,
                            isEmpty: countForType(category.name) == 0,
                            isEditing: isEditing,
                            action: {
                                selectedContentType = (selectedContentType == category.name) ? nil : category.name
                            },
                            onEdit: {
                                prepareRename(for: category)
                            },
                            onDelete: {
                                prepareDelete(for: category)
                            },
                            canDelete: category.name != "Misc"
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .onMove(perform: moveCategories)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollIndicators(.hidden)
                .scrollDisabled(isMenuDragging) // Désactiver le scroll pendant le swipe
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentMargins(.top, userPreferences.showCategoryTitles ? 72 : 30) // 82 avec titres (30 base + 52 titre), 30 sans titres
                .contentMargins(.bottom, 220)
                .animation(.easeInOut, value: isEditing)
                }
                
                // Dégradé de fondu en bas pour masquer les catégories sous le bouton
                VStack {
                    Spacer()
                    
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.clear, location: 0.0),
                            .init(color: Color(UIColor.systemBackground).opacity(0.5), location: 0.2),
                            .init(color: Color(UIColor.systemBackground).opacity(0.8), location: 0.4),
                            .init(color: Color(UIColor.systemBackground).opacity(0.95), location: 0.6),
                            .init(color: Color(UIColor.systemBackground), location: 0.7)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 180)
                    .allowsHitTesting(false)
                }
            }
            
            // Pas de bouton local de fermeture d'édition (géré via FloatingSearchBar)
            
        }
        .ignoresSafeArea(edges: .bottom)
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
        .onChange(of: isMenuOpen) { _, isOpen in
            guard !isOpen else { return }
            resetEditingState()
        }
        .onDisappear(perform: resetEditingState)
        // Notifications reçues depuis FloatingSearchBar
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FilterMenuViewRequestEditCategories"))) { _ in
            if !isEditing { toggleEditing() }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FilterMenuViewRequestCreateCategory"))) { _ in
            if !isEditing { toggleEditing() }
            prepareCreateCategory()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FilterMenuViewRequestCloseEditing"))) { _ in
            resetEditingState()
        }
        .sheet(isPresented: $isShowingRenameSheet) {
            RenameCategorySheet(
                name: $renameText,
                onCancel: resetRenameState,
                onSave: handleSaveAction
            )
        }
        .alert("Delete Category?", isPresented: $isShowingDeleteAlert, presenting: categoryToDelete) { category in
            Button("Cancel", role: .cancel, action: resetDeleteState)
            Button("Delete", role: .destructive) { deleteCategory(category) }
        } message: { category in
            Text("All items will move to Misc before deleting \(category.name).")
        }
    }
}


// MARK: - Private helpers
private extension FilterMenuView {
    func toggleEditing() {
        hapticTrigger += 1
        withAnimation(.easeInOut) {
            isEditing.toggle()
        }
    }
    
    func resetEditingState() {
        guard isEditing else { return }
        isEditing = false
        // Notifier la FloatingSearchBar pour désactiver l'état d'édition
        NotificationCenter.default.post(name: Notification.Name("FilterMenuViewRequestCloseEditing"), object: nil)
    }
    
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

        if selectedContentType == oldName {
            selectedContentType = newName
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
        selectedContentType = nil // Retourner sur "All" au lieu de sélectionner la catégorie vide
        resetEditingState() // Désactiver le mode édition après création
        resetRenameState()
    }
    
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
        
        if selectedContentType == name {
            selectedContentType = nil
        }
        
        resetDeleteState()
    }
    
    // MARK: - Computed Properties
    private var processedCategoryName: String {
        renameText.trimmingCharacters(in: .whitespacesAndNewlines).capitalized
    }
    
    // MARK: - Validation
    private func validateCategoryName(_ name: String, excludingId: UUID? = nil) -> Bool {
        guard !name.isEmpty else { return false }
        
        return !allCategories.contains { category in
            category.name.caseInsensitiveCompare(name) == .orderedSame &&
            category.id != excludingId
        }
    }
    
    // MARK: - State Management
    private func handleSaveAction() {
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
    
    private func resetDeleteState() {
        categoryToDelete = nil
        isShowingDeleteAlert = false
    }
}

// MARK: - Preview
#Preview {
    let schema = Schema([ContentItem.self, Category.self])
    let configuration = ModelConfiguration(
        schema: schema,
        groupContainer: .identifier(AppConstants.groupID),
        cloudKitDatabase: .private(AppConstants.cloudKitContainerID)
    )
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    
    return FilterMenuView(
        selectedContentType: .constant(nil),
        isMenuOpen: .constant(false),
        isMenuDragging: false,
        onOpenAbout: {},
        onOpenSettings: {}
    )
    .modelContainer(container)
}
