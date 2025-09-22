import SwiftUI

struct ContentItemContextMenu: View {
    let item: ContentItem
    let contentService: ContentServiceCoreData
    let onStorageStatsRefresh: () -> Void
    let onDeleteRequest: () -> Void
    @StateObject private var coreDataService = CoreDataService.shared
    
    // Initialisation directe des catégories pour éviter le délai d'affichage
    private var categoryNames: [String] {
        coreDataService.fetchCategoryNames()
    }
    
    var body: some View {
        VStack {
            // Partage natif
            if let url = item.url, !url.hasPrefix("file://") {
                Button(action: {
                    shareContent()
                }) {
                    Label("Partager", systemImage: "square.and.arrow.up")
                }
            }
            
            // Menu de changement de catégorie
            Menu {
                ForEach(categoryNames, id: \.self) { categoryName in
                    if categoryName != item.safeCategoryName {
                        Button(action: {
                            changeCategory(to: categoryName)
                        }) {
                            Label(categoryName, systemImage: "folder")
                        }
                    }
                }
            } label: {
                Label("Changer de catégorie", systemImage: "folder")
            }
            
            // Masquer/Afficher
            Button(action: {
                toggleItemVisibility()
            }) {
                Label(item.isHidden ? "Afficher" : "Masquer", 
                      systemImage: item.isHidden ? "eye" : "eye.slash")
            }
            
            // Supprimer
            Button(action: {
                onDeleteRequest()
            }) {
                Label("Supprimer", systemImage: "trash")
                    .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - Actions
    
    private func shareContent() {
        guard let url = item.url, let shareURL = URL(string: url) else { return }
        
        let activityViewController = UIActivityViewController(
            activityItems: [shareURL],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityViewController, animated: true)
        }
    }
    
    private func changeCategory(to category: String) {
        contentService.updateContentItem(item, categoryName: category)
        onStorageStatsRefresh()
    }
    
    private func toggleItemVisibility() {
        contentService.updateContentItem(item, isHidden: !item.isHidden)
        onStorageStatsRefresh()
    }
}
