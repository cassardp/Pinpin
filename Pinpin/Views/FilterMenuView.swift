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
    
    // Récupère toutes les catégories avec ordre personnalisé et nettoyage anti-doublons
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
        
        // Nettoyer les doublons côté SwiftData (sécurité supplémentaire)
        let uniqueCategories = Array(Set(visibleCategories.map { $0.name }))
        
        // Appliquer l'ordre personnalisé avec nettoyage intégré
        return categoryOrderService.orderedCategories(from: uniqueCategories)
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
        ZStack {
            // Background
            Color(UIColor.systemBackground)
                .onTapGesture {
                    // Perdre le focus du TextField avec SwiftUI natif
                    isTextFieldFocused = false
                }
            
            // Liste centrée verticalement avec dégradés de fondu
            ZStack {
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
                .scrollDisabled(isMenuDragging) // Désactiver le scroll pendant le swipe
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentMargins(.top, 90)
                .contentMargins(.bottom, 220)
                .animation(.easeInOut, value: isEditing)
                }
                
                // Dégradé de fondu en haut (ignore la safe area)
                VStack {
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color(UIColor.systemBackground), location: 0.0),
                            .init(color: Color(UIColor.systemBackground).opacity(0.9), location: 0.3),
                            .init(color: Color(UIColor.systemBackground).opacity(0.6), location: 0.6),
                            .init(color: Color.clear, location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 180)
                    .allowsHitTesting(false)
                    .ignoresSafeArea(.all, edges: .top)
                    
                    Spacer()
                }
                
                // Dégradé de fondu en bas
                VStack {
                    Spacer()
                    
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.clear, location: 0.0),
                            .init(color: Color(UIColor.systemBackground).opacity(0.6), location: 0.4),
                            .init(color: Color(UIColor.systemBackground).opacity(0.9), location: 0.7),
                            .init(color: Color(UIColor.systemBackground), location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 150)
                    .allowsHitTesting(false)
                }
            }
            
            // Menu ellipsis en bas à gauche
            VStack {
                Spacer()
                
                HStack {
                    if isEditing {
                        // Mode édition : bouton checkmark simple
                        Button {
                            hapticFeedback()
                            toggleEditing()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.primary)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                )
                        }
                        .padding(.leading, 32)
                    } else {
                        // Mode normal : menu ellipsis
                        Menu {
                            Button {
                                hapticFeedback()
                                onOpenSettings()
                            } label: {
                                Label("Settings", systemImage: "gearshape")
                            }
                            
                            Divider()
                            
                            Button {
                                hapticFeedback()
                                toggleEditing()
                            } label: {
                                Label("Edit category", systemImage: "pencil")
                            }
                            
                            Button {
                                hapticFeedback()
                                prepareCreateCategory()
                            } label: {
                                Label("Add category", systemImage: "plus")
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
                        .padding(.leading, 32)
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 48)
            }
            
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            // Nettoyage préventif des doublons au démarrage
            if categoryOrderService.hasDuplicates() {
                print("⚠️ Doublons détectés dans FilterMenuView: \(categoryOrderService.getDuplicates())")
                categoryOrderService.cleanupDuplicates()
            }
        }
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
            selectedContentType = nil // Retourner sur "All" au lieu de sélectionner la catégorie vide
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
        isMenuDragging: false,
        onOpenAbout: {},
        onOpenSettings: {}
    )
    .modelContainer(DataService.shared.container)
}
