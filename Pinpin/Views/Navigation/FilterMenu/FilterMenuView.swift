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

    @Binding var selectedContentType: String?
    @Binding var isMenuOpen: Bool
    @Binding var isEditingCategories: Bool
    var isMenuDragging: Bool
    @FocusState private var isTextFieldFocused: Bool
    
    /// Signature représentant l'ordre actuel des catégories (pour détecter les changements de tri)
    private var categorySortOrderSignature: String {
        allCategories.map { "\($0.id.uuidString):\($0.sortOrder)" }.joined(separator: ",")
    }
    
    // Manager pour toute la logique métier
    @State private var manager: CategoryManager?
    
    var body: some View {
        content
            .ignoresSafeArea(edges: .bottom)
            .sensoryFeedback(.impact(weight: .light), trigger: manager?.hapticTrigger ?? 0)
            .onAppear(perform: setupManager)
            .onChange(of: allCategories.count, updateManagerForCategories)
            .onChange(of: categorySortOrderSignature, updateManagerForCategories)
            .onChange(of: contentItems.count, updateManagerForItems)
            .onChange(of: isEditingCategories) { _, newValue in
                manager?.isEditingCategories = newValue
            }
            .onReceive(createCategoryPublisher, perform: handleCreateCategoryNotification)
            .onReceive(toggleEditCategoriesPublisher, perform: handleToggleEditCategoriesNotification)
            .sheet(isPresented: renameSheetBinding, content: renameSheet)
            .alert("Delete Category?", isPresented: deleteAlertBinding, presenting: manager?.categoryToDelete, actions: deleteAlertActions, message: deleteAlertMessage)
    }
    
    // MARK: - Content
    private var content: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .onTapGesture {
                    isTextFieldFocused = false
                }

            if let manager {
                CategoryList(
                    manager: manager,
                    contentItems: contentItems,
                    isMenuDragging: isMenuDragging,
                    selectedContentType: $selectedContentType
                )
            }
        }
    }
    
    // MARK: - Bindings
    private var renameSheetBinding: Binding<Bool> {
        Binding(
            get: { manager?.isShowingRenameSheet ?? false },
            set: { if !$0 { manager?.resetRenameState() } }
        )
    }
    
    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { manager?.isShowingDeleteAlert ?? false },
            set: { if !$0 { manager?.resetDeleteState() } }
        )
    }
    
    // MARK: - Publishers
    private var createCategoryPublisher: NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: Notification.Name("FilterMenuViewRequestCreateCategory"))
    }
    
    private var toggleEditCategoriesPublisher: NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: Notification.Name("FilterMenuViewRequestToggleEditCategories"))
    }
    
    // MARK: - Handlers
    private func setupManager() {
        if manager == nil {
            manager = CategoryManager(
                modelContext: modelContext,
                allCategories: allCategories,
                contentItems: contentItems,
                selectedContentType: $selectedContentType
            )
        }
    }
    
    private func updateManagerForCategories() {
        updateManager()
    }
    
    private func updateManagerForItems() {
        updateManager()
    }
    
    private func updateManager() {
        manager = CategoryManager(
            modelContext: modelContext,
            allCategories: allCategories,
            contentItems: contentItems,
            selectedContentType: $selectedContentType
        )
        manager?.isEditingCategories = isEditingCategories
    }
    
    private func handleCreateCategoryNotification(_ notification: Notification) {
        manager?.prepareCreateCategory()
    }
    
    private func handleToggleEditCategoriesNotification(_ notification: Notification) {
        // MainView manages the state, we just need to react via binding
    }
    
    private func renameSheet() -> some View {
        Group {
            if let manager {
                RenameCategorySheet(
                    name: Binding(
                        get: { manager.renameText },
                        set: { manager.renameText = $0 }
                    ),
                    onCancel: { manager.resetRenameState() },
                    onSave: { manager.handleSaveAction() }
                )
            }
        }
    }
    
    private func deleteAlertActions(category: Category) -> some View {
        Group {
            Button("Cancel", role: .cancel) {
                manager?.resetDeleteState()
            }
            Button("Delete", role: .destructive) {
                manager?.deleteCategory(category)
            }
        }
    }
    
    private func deleteAlertMessage(category: Category) -> some View {
        Text("All items will move to Misc before deleting \(category.name).")
    }
}



