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
    
    @StateObject private var userPreferences = UserPreferences.shared
    @StateObject private var categoryOrderService = CategoryOrderService.shared
    private let dataService = DataService.shared
    @Binding var selectedContentType: String?
    var onOpenAbout: () -> Void
    @State private var isEditing = false
    @State private var categoryToRename: Category?
    @State private var renameText: String = ""
    @State private var isShowingRenameSheet = false
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
        if type == nil {
            return contentItems.count
        }
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
        ZStack(alignment: .topLeading) {
            // Background
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
                .onTapGesture {
                    // Perdre le focus du TextField
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            
            // Liste centrée verticalement - solution simple
            List {
                // Bouton d'édition
                HStack {
                    Spacer()
                    Button(action: toggleEditing) {
                        Text(isEditing ? "Done" : "Edit")
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.plain)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .padding(.horizontal, 32)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .contentShape(Rectangle())

                // Spacer invisible pour centrer
                Color.clear
                    .frame(height: 0)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                
                // Option "Tout"
                CategoryListRow(
                    isSelected: selectedContentType == nil,
                    title: "All",
                    isEmpty: false,
                    isEditing: false,
                    action: {
                        selectedContentType = nil
                    },
                    onEdit: nil,
                    onDelete: nil,
                    canDelete: false
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
                
                // Spacer invisible pour centrer
                Color.clear
                    .frame(height: 0)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentMargins(.vertical, 60)
            .animation(.easeInOut, value: isEditing)
            
        }
        .sheet(isPresented: $isShowingRenameSheet) {
            RenameCategorySheet(
                name: $renameText,
                onCancel: resetRenameState,
                onSave: {
                    guard let categoryToRename else {
                        resetRenameState()
                        return
                    }
                    saveRenamedCategory(categoryToRename)
                }
            )
        }
        .alert("Delete category?", isPresented: $isShowingDeleteAlert, presenting: categoryToDelete) { category in
            Button("Cancel", role: .cancel) {
                categoryToDelete = nil
            }
            Button("Delete", role: .destructive) {
                deleteCategory(category)
            }
        } message: { category in
            Text("All items will move to Misc before deleting \(category.name).")
        }
    }
}

// MARK: - CategoryListRow Component
struct CategoryListRow: View {
    let isSelected: Bool
    let title: String
    let isEmpty: Bool
    let isEditing: Bool
    let action: () -> Void
    let onEdit: (() -> Void)?
    let onDelete: (() -> Void)?
    let canDelete: Bool
    
    init(
        isSelected: Bool,
        title: String,
        isEmpty: Bool,
        isEditing: Bool = false,
        action: @escaping () -> Void,
        onEdit: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        canDelete: Bool = true
    ) {
        self.isSelected = isSelected
        self.title = title
        self.isEmpty = isEmpty
        self.isEditing = isEditing
        self.action = action
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.canDelete = canDelete
    }
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                if isSelected {
                    Circle()
                        .fill(isEmpty ? Color.secondary : Color.primary)
                        .frame(width: 8, height: 8)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }

                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(isEmpty ? .secondary : .primary)
            }
            .padding(.vertical, -4)
            
            Spacer()
            
            if isEditing {
                HStack(spacing: 16) {
                    if let onEdit {
                        Button(action: onEdit) {
                            Image(systemName: "pencil")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.primary)
                    }
                    if let onDelete, canDelete {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.red)
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 32)
        .contentShape(Rectangle())
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(.easeInOut) {
                action()
            }
        }
        .opacity(isEmpty ? 0.6 : 1.0)
    }
}

// MARK: - Private helpers
private extension FilterMenuView {
    func toggleEditing() {
        withAnimation(.easeInOut) {
            isEditing.toggle()
        }
    }
    
    func prepareRename(for category: Category) {
        renameText = category.name
        categoryToRename = category
        isShowingRenameSheet = true
    }
    
    func resetRenameState() {
        renameText = ""
        categoryToRename = nil
        isShowingRenameSheet = false
    }
    
    func saveRenamedCategory(_ category: Category) {
        let newName = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        let oldName = category.name
        guard !newName.isEmpty, newName != oldName else {
            resetRenameState()
            return
        }
        guard !allCategories.contains(where: { $0.name.caseInsensitiveCompare(newName) == .orderedSame && $0.id != category.id }) else {
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
                }
                
                Spacer()
            }
            .background(Color(UIColor.systemBackground))
            .ignoresSafeArea(.all)
            .animation(.easeInOut(duration: 0.3), value: name.isEmpty)
            .navigationTitle("Rename")
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
        onOpenAbout: {}
    )
    .modelContainer(DataService.shared.container)
}
