import SwiftUI

struct ContentItemContextMenu: View {
    let item: ContentItem
    let contentService: ContentServiceCoreData
    let onStorageStatsRefresh: () -> Void
    
    // MARK: - Computed Properties
    
    private var detectedLabels: [String] {
        guard let metadata = item.metadata as? [String: String],
              let labelsString = metadata["detected_labels"],
              !labelsString.isEmpty else {
            return []
        }
        return labelsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    private var detectionSource: String? {
        guard let metadata = item.metadata as? [String: String] else { return nil }
        return metadata["detected_labels_source"]
    }
    
    private var detectionModel: String? {
        guard let metadata = item.metadata as? [String: String] else { return nil }
        return metadata["detected_model"]
    }
    
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
        
        // Sous-menu Tags (detected_labels)
        if !detectedLabels.isEmpty {
            Menu {
                ForEach(detectedLabels, id: \.self) { tag in
                    Button(action: {
                        // Action future: filtrer par tag ou copier
                    }) {
                        Label(tag, systemImage: "tag")
                    }
                }
                
                Divider()
                
                // Informations sur la source de détection
                if let source = detectionSource {
                    Button(action: {}) {
                        Label("Source: \(source)", systemImage: "info.circle")
                    }
                    .disabled(true)
                }
                
                if let model = detectionModel {
                    Button(action: {}) {
                        Label("Modèle: \(model)", systemImage: "cpu")
                    }
                    .disabled(true)
                }
            } label: {
                Label("Tags (\(detectedLabels.count))", systemImage: "tag.fill")
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
