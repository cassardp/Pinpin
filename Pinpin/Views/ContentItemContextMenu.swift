import SwiftUI
import SwiftData
import UIKit
import SafariServices

struct ContentItemContextMenu: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.sortOrder, order: .forward)
    private var allCategories: [Category]
    
    let item: ContentItem
    let onStorageStatsRefresh: () -> Void
    let onDeleteRequest: () -> Void
    
    // Initialisation directe des catégories pour éviter le délai d'affichage
    private var categoryNames: [String] {
        allCategories.map { $0.name }
    }
    
    // Afficher "Search Similar" seulement si une image exploitable est disponible
    private var canSearchSimilar: Bool {
        if item.imageData != nil { return true }
        if let t = item.thumbnailUrl, !t.isEmpty, !t.hasPrefix("images/"), !t.hasPrefix("file://") { return true }
        return false
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
            
            // Search Similar with submenu (liste par défaut)
            if canSearchSimilar {
                Menu {
                    ForEach(SearchSite.defaultSites) { site in
                        Button(action: {
                            searchSimilarProducts(query: site.query)
                        }) {
                            Label(site.name, systemImage: site.iconName)
                        }
                    }
                } label: {
                    Label("Search Similar", systemImage: "binoculars")
                }
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
        guard let targetCategory = allCategories.first(where: { $0.name == category }) else { return }
        item.category = targetCategory
        try? modelContext.save()
        onStorageStatsRefresh()
    }
    
    private func searchSimilarProducts(query: String?) {
        SimilarSearchService.searchSimilarProducts(for: item, query: query)
    }
}
