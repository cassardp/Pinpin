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
            // Share
            if let url = item.url, !url.hasPrefix("file://") {
                Button(action: {
                    shareContent()
                }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
            
            // Category menu
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
                Label(item.safeCategoryName.capitalized, systemImage: "folder")
            }
            
            // Search Similar
            Button(action: {
                searchSimilarProducts()
            }) {
                Label("Search Similar", systemImage: "binoculars")
            }
            
            Divider()
            
            // Delete
            Button(role: .destructive, action: {
                onDeleteRequest()
            }) {
                Label("Delete", systemImage: "trash")
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
    
    private func searchSimilarProducts() {
        // Logique à implémenter
    }
}
