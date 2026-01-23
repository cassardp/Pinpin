import SwiftUI
import SwiftData

// MARK: - CategoryList
struct CategoryList: View {
    // MARK: - Properties
    let manager: CategoryManager
    let contentItems: [ContentItem]
    let isMenuDragging: Bool
    
    @Binding var selectedContentType: String?
    
    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                List {
                    // Option "Tout" (non déplaçable, pas de mode édition)
                    CategoryListRow(
                        isSelected: selectedContentType == nil,
                        title: "All",
                        isEmpty: contentItems.isEmpty,
                        action: { selectedContentType = nil }
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .moveDisabled(true)
                    
                    // Types dynamiques avec réorganisation native
                    ForEach(manager.availableCategories, id: \.id) { category in
                        CategoryListRow(
                            isSelected: selectedContentType == category.name,
                            title: category.name.capitalized,
                            isEmpty: manager.countForType(category.name) == 0,
                            action: {
                                selectedContentType = (selectedContentType == category.name) ? nil : category.name
                            },
                            onRename: {
                                manager.prepareRename(for: category)
                            },
                            onDelete: {
                                manager.prepareDelete(for: category)
                            },
                            canDelete: category.name != "Misc",
                            isEditing: manager.isEditingCategories
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .onMove(perform: manager.isEditingCategories ? manager.moveCategories : nil)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollIndicators(.hidden)
                .scrollDisabled(isMenuDragging)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentMargins(.top, 30)
                .contentMargins(.bottom, 220)
                .environment(\.editMode, .constant(manager.isEditingCategories ? .active : .inactive))
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
    }
}
