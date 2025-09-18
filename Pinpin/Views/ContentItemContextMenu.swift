import SwiftUI

struct ContentItemContextMenu: View {
    let item: ContentItem
    let contentService: ContentServiceCoreData
    let onStorageStatsRefresh: () -> Void
    
    // MARK: - Computed Properties
    
    private var metadata: [String: String] {
        return (item.metadata as? [String: String]) ?? [:]
    }
    
    private var detectedLabels: [String] {
        guard let labelsString = metadata["detected_labels"], !labelsString.isEmpty else {
            return []
        }
        return labelsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    private var detectedConfidences: [String] {
        guard let confidencesString = metadata["detected_confidences"], !confidencesString.isEmpty else {
            return []
        }
        return confidencesString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    private var detectionSource: String? {
        return metadata["detected_labels_source"]
    }
    
    private var detectionModel: String? {
        return metadata["detected_model"]
    }
    
    private var bestLabel: String? {
        return metadata["best_label"]
    }
    
    private var bestConfidence: String? {
        return metadata["best_confidence"]
    }
    
    private var mainObjectLabel: String? {
        return metadata["main_object_label"]
    }
    
    private var mainObjectConfidence: String? {
        return metadata["main_object_confidence"]
    }
    
    private var mainObjectAlternatives: [String] {
        guard let alternativesString = metadata["main_object_alternatives"], !alternativesString.isEmpty else {
            return []
        }
        return alternativesString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    private var mainObjectColorEN: String? {
        return metadata["main_object_color_name"]
    }
    
    private var mainObjectColorFR: String? {
        return metadata["main_object_color_name_fr"]
    }
    
    private var ocrText: String? {
        return metadata["ocr_text"]
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
        
        // Sous-menu Vision Analysis (informations détaillées)
        if !detectedLabels.isEmpty || bestLabel != nil || mainObjectLabel != nil {
            Menu {
                // Meilleur label avec confiance
                if let best = bestLabel, let confidence = bestConfidence {
                    Button(action: {}) {
                        Label("🏆 \(best) (\(confidence))", systemImage: "star.fill")
                    }
                    .disabled(true)
                }
                
                if bestLabel != nil {
                    Divider()
                }
                
                // Tous les labels avec leurs scores
                ForEach(Array(zip(detectedLabels, detectedConfidences)), id: \.0) { label, confidence in
                    Button(action: {}) {
                        Label("\(label) (\(confidence))", systemImage: "tag")
                    }
                    .disabled(true)
                }
                
                if !detectedLabels.isEmpty && (mainObjectLabel != nil || detectionSource != nil) {
                    Divider()
                }
                
                // Sujet principal
                if let mainLabel = mainObjectLabel {
                    Button(action: {}) {
                        if let confidence = mainObjectConfidence {
                            Label("🎯 Sujet: \(mainLabel) (\(confidence))", systemImage: "viewfinder")
                        } else {
                            Label("🎯 Sujet: \(mainLabel)", systemImage: "viewfinder")
                        }
                    }
                    .disabled(true)
                }
                
                // Alternatives du sujet principal
                if !mainObjectAlternatives.isEmpty {
                    ForEach(mainObjectAlternatives, id: \.self) { alt in
                        Button(action: {}) {
                            Label("↳ \(alt)", systemImage: "arrow.turn.down.right")
                        }
                        .disabled(true)
                    }
                }
                
                // Couleurs
                if let colorEN = mainObjectColorEN, let colorFR = mainObjectColorFR {
                    Button(action: {}) {
                        Label("🎨 \(colorFR) / \(colorEN)", systemImage: "paintpalette")
                    }
                    .disabled(true)
                }
                
                if (mainObjectLabel != nil || mainObjectColorEN != nil) && detectionSource != nil {
                    Divider()
                }
                
                // Informations techniques
                if let source = detectionSource {
                    Button(action: {}) {
                        Label("📊 Source: \(source)", systemImage: "info.circle")
                    }
                    .disabled(true)
                }
                
                if let model = detectionModel {
                    Button(action: {}) {
                        Label("🤖 Modèle: \(model)", systemImage: "cpu")
                    }
                    .disabled(true)
                }
            } label: {
                Label("Vision Analysis (\(detectedLabels.count))", systemImage: "eye.fill")
            }
        }
        
        // Sous-menu OCR si du texte a été détecté
        if let ocr = ocrText, !ocr.isEmpty {
            Menu {
                Button(action: {
                    UIPasteboard.general.string = ocr
                }) {
                    Label("Copier le texte", systemImage: "doc.on.doc")
                }
                
                Divider()
                
                // Afficher le texte (tronqué si trop long)
                let displayText = ocr.count > 50 ? String(ocr.prefix(50)) + "..." : ocr
                Button(action: {}) {
                    Label(displayText, systemImage: "text.alignleft")
                }
                .disabled(true)
            } label: {
                Label("OCR Text", systemImage: "text.viewfinder")
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
