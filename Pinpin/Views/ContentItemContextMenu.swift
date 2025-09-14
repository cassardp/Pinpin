import SwiftUI

struct ContentItemContextMenu: View {
    let item: ContentItem
    let contentService: ContentServiceCoreData
    let onStorageStatsRefresh: () -> Void
    
    var body: some View {
        // Afficher le menu de reclassification seulement si ce n'est pas un item de type "text"
        if item.contentTypeEnum != .text {
            Menu {
                ForEach(ContentType.allCases, id: \.self) { contentType in
                    if contentType != item.contentTypeEnum && contentType != .text {
                        Button(action: {
                            reclassifyItem(to: contentType)
                        }) {
                            Label(contentType.displayName, systemImage: "folder")
                        }
                    }
                }
            } label: {
                Label(item.contentTypeEnum.displayName, systemImage: "folder")
            }
        }
        
        // Context menu trimmed: removed Hide and Delete actions
    }
    
    // MARK: - Actions
    
    // Hide action removed from context menu
    
    // Delete action removed from context menu
    
    private func reclassifyItem(to newType: ContentType) {
        withAnimation(.easeInOut(duration: 0.3)) {
            item.contentType = newType.rawValue
            item.updatedAt = Date()
        }
        
        // Forcer la notification des changements
        item.objectWillChange.send()
        
        contentService.updateContentItem(item)
    }
    

}

// MARK: - Preview

#Preview {
    ContentItemContextMenu(
        item: ContentItem(),
        contentService: ContentServiceCoreData(),
        onStorageStatsRefresh: {}
    )
}
