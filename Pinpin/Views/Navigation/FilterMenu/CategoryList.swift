import SwiftUI
import SwiftData

// MARK: - CategoryList
struct CategoryList: View {
    // MARK: - Properties
    let manager: CategoryManager
    let contentItems: [ContentItem]
    let isMenuDragging: Bool
    let showCategoryTitles: Bool
    
    @Binding var selectedContentType: String?
    
    var body: some View {
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
                    ForEach(manager.availableCategories, id: \.id) { category in
                        CategoryListRow(
                            isSelected: selectedContentType == category.name,
                            title: category.name.capitalized,
                            isEmpty: manager.countForType(category.name) == 0,
                            isEditing: manager.isEditing,
                            action: {
                                selectedContentType = (selectedContentType == category.name) ? nil : category.name
                            },
                            onEdit: {
                                manager.prepareRename(for: category)
                            },
                            onDelete: {
                                manager.prepareDelete(for: category)
                            },
                            canDelete: category.name != "Misc"
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .onMove(perform: manager.moveCategories)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollIndicators(.hidden)
                .scrollDisabled(isMenuDragging) // Désactiver le scroll pendant le swipe
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentMargins(.top, showCategoryTitles ? 72 : 30) // 82 avec titres (30 base + 52 titre), 30 sans titres
                .contentMargins(.bottom, 220)
                .animation(.easeInOut, value: manager.isEditing)
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
