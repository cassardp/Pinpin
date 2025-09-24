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
    
    @StateObject private var categoryOrderService = CategoryOrderService.shared
    private let dataService = DataService.shared
    @Binding var selectedContentType: String?
    @Binding var isMenuOpen: Bool
    var onOpenAbout: () -> Void
    var onOpenSettings: () -> Void
    @State private var isEditing = false
    @State private var categoryToRename: Category?
    @State private var renameText: String = ""
    @State private var isShowingRenameSheet = false
    @State private var isCreatingCategory = false
    @State private var categoryToDelete: Category?
    @State private var isShowingDeleteAlert = false
    
    // Récupère toutes les catégories avec ordre personnalisé
    private var availableTypes: [String] {
        // Filtrer les catégories "Misc" vides pour les cacher
        let visibleCategories = allCategories.filter { category in
            // Toujours afficher les catégories non-Misc
            if category.name != "Misc" {
                return true
            }
            // Pour "Misc", l'afficher seulement si elle a des items
            return countForType(category.name) > 0
        }
        
        let categoryNames = visibleCategories.map { $0.name }
        
        // Appliquer l'ordre personnalisé
        return categoryOrderService.orderedCategories(from: categoryNames)
    }
    
    // Compte les items par type
    private func countForType(_ type: String?) -> Int {
        guard let type = type else { return contentItems.count }
        return contentItems.filter { $0.safeCategoryName == type }.count
    }
    
    // Méthode pour déplacer les catégories (fonctionnalité native SwiftUI)
    private func moveCategories(from source: IndexSet, to destination: Int) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            categoryOrderService.reorderCategories(from: source, to: destination)
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background
            Color(UIColor.systemBackground)
                .onTapGesture {
                    // Perdre le focus du TextField
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            
            // Liste centrée verticalement - solution simple
            ScrollViewReader { proxy in
                List {

                // Option "Tout"
                CategoryListRow(
                    isSelected: selectedContentType == nil,
                    title: "All",
                    isEmpty: false,
                    isEditing: false,
                    action: { selectedContentType = nil }
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                
                // Types dynamiques avec réorganisation native
                ForEach(availableTypes, id: \.self) { type in
                    let category = allCategories.first(where: { $0.name == type })
                    CategoryListRow(
                        isSelected: selectedContentType == type,
                        title: type.capitalized,
                        isEmpty: countForType(type) == 0,
                        isEditing: isEditing,
                        action: {
                            selectedContentType = (selectedContentType == type) ? nil : type
                        },
                        onEdit: {
                            guard let category else { return }
                            prepareRename(for: category)
                        },
                        onDelete: {
                            guard let category else { return }
                            prepareDelete(for: category)
                        },
                        canDelete: category?.name != "Misc"
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .onMove(perform: moveCategories)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .top, spacing: 0) {
                Color.clear.frame(height: 99)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: 199)
            }
            .animation(.easeInOut, value: isEditing)
            }
            
            // Menu ellipsis en bas à gauche
            
            
                    HStack {
                        if isEditing {
                            // Mode édition : bouton checkmark simple
                            Button {
                                hapticFeedback()
                                toggleEditing()
                            } label: {
                                Image(systemName: "checkmark")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                    )
                            }
                            .padding(.leading, 16)
                        } else {
                            // Mode normal : menu ellipsis
                            Menu {
                                Button {
                                    hapticFeedback()
                                    prepareCreateCategory()
                                } label: {
                                    Label("Add", systemImage: "plus")
                                }
                                
                                Button {
                                    hapticFeedback()
                                    toggleEditing()
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                
                                Divider()
                                
                                Button {
                                    hapticFeedback()
                                    onOpenSettings()
                                } label: {
                                    Label("Settings", systemImage: "gearshape")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                    )
                            }
                            .padding(.leading, 16)
                        }
                        
                        Spacer()
                }
                .padding(.bottom, 48)
                .padding(.leading, 16)
            
        }
        .ignoresSafeArea(edges: .bottom)
        .onChange(of: isMenuOpen) { _, isOpen in
            guard !isOpen else { return }
            resetEditingState()
        }
        .onDisappear(perform: resetEditingState)
        .sheet(isPresented: $isShowingRenameSheet) {
            RenameCategorySheet(
                name: $renameText,
                onCancel: resetRenameState,
onSave: handleSaveAction
            )
        }
.alert("Delete category?", isPresented: $isShowingDeleteAlert, presenting: categoryToDelete) { category in
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
        hapticFeedback()
        withAnimation(.easeInOut) {
            isEditing.toggle()
        }
    }
    
    func hapticFeedback() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

func resetEditingState() {
        guard isEditing else { return }
        isEditing = false
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
        category.updatedAt = Date()
        
        do {
            try modelContext.save()
            categoryOrderService.renameCategory(oldName: oldName, newName: newName)
            if selectedContentType == oldName {
                selectedContentType = newName
            }
        } catch {
            print("Failed to rename category: \(error)")
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
        newCategory.sortOrder = Int32(allCategories.count)
        newCategory.createdAt = Date()
        newCategory.updatedAt = Date()

        modelContext.insert(newCategory)
        do {
            try modelContext.save()
            selectedContentType = newName
        } catch {
            print("Failed to create category: \(error)")
        }
        resetRenameState()
    }
    
    func prepareDelete(for category: Category) {
        categoryToDelete = category
        isShowingDeleteAlert = true
    }
    
func deleteCategory(_ category: Category) {
        let name = category.name
        dataService.deleteCategory(category)
        categoryOrderService.removeCategory(named: name)
        
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

// MARK: - Rename sheet
struct RenameCategorySheet: View {
    @Binding var name: String
    let onCancel: () -> Void
    let onSave: () -> Void
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                VStack(spacing: 40) {
                    TextField("Category Name", text: $name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.horizontal, 40)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .focused($isFieldFocused)
                        .onSubmit {
                            // Vérifier que le nom n'est pas vide avant de sauvegarder
                            if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                onSave()
                            }
                        }
                }
                
                Spacer()
            }
            .background(Color(UIColor.systemBackground))
            .ignoresSafeArea(.all)
            .animation(.easeInOut(duration: 0.3), value: name.isEmpty)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isFieldFocused = true
                }
            }
        }
    }
}


// MARK: - Preview
#Preview {
    FilterMenuView(
        selectedContentType: .constant(nil),
        isMenuOpen: .constant(false),
        onOpenAbout: {},
        onOpenSettings: {}
    )
    .modelContainer(DataService.shared.container)
}
