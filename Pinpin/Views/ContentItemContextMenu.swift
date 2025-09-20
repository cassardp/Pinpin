import SwiftUI

struct ContentItemContextMenu: View {
    let item: ContentItem
    let contentService: ContentServiceCoreData
    let onStorageStatsRefresh: () -> Void
    let onDeleteRequest: () -> Void
    @StateObject private var userPreferences = UserPreferences.shared
    
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
    
    // MARK: - Helper Methods
    
    /// Vérifie si l'item contient des fichiers locaux
    private func isLocalFile() -> Bool {
        // Vérifier l'URL principale
        if let url = item.url, url.hasPrefix("file://") {
            return true
        }
        
        // Vérifier l'URL de l'image
        if let thumbnailUrl = item.thumbnailUrl, thumbnailUrl.hasPrefix("file://") {
            return true
        }
        
        return false
    }
    
    /// Vérifie si un label est considéré comme générique (exclu de la classification)
    private func isGenericLabel(_ label: String) -> Bool {
        let genericLabels = [
            "structure", "wood_processed", "liquid", "water", "water_body",
            "material", "container", "object", "item", "thing", "stuff", "conveyance",
            "housewares", "office_supplies", "tool", "equipment", "device",
            "people", "person", "human", "crowd", "wood_natural", "raw_glass", "textile", "adult",
            "dashboard",  "machine",
        ]
        
        let normalizedLabel = label.lowercased()
        return genericLabels.contains(normalizedLabel)
    }
    
    var body: some View {
        VStack {
            // Partage natif - utilise les items disponibles (seulement si pas de fichier local)
            if !isLocalFile() {
                Button(action: {
                    shareContent()
                }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
            
            // Menu de reclassification pour tous les types
            Menu {
                ForEach(ContentType.orderedCases, id: \.self) { contentType in
                    if contentType != item.contentTypeEnum {
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
            
            // Sous-menu Vision Analysis (informations détaillées) - Affiché seulement en dev mode
            if userPreferences.devMode && (!detectedLabels.isEmpty || bestLabel != nil || mainObjectLabel != nil) {
            Menu {
                // Meilleur label avec confiance
                if let best = bestLabel, let confidence = bestConfidence {
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "star.fill")
                            if isGenericLabel(best) {
                                Text("🏆 \(best) (\(confidence)) [EXCLU]")
                                    .foregroundColor(.red)
                            } else {
                                Text("🏆 \(best) (\(confidence))")
                            }
                        }
                    }
                    .disabled(true)
                }
                
                if bestLabel != nil {
                    Divider()
                }
                
                // Tous les labels avec leurs scores
                ForEach(Array(zip(detectedLabels, detectedConfidences)), id: \.0) { label, confidence in
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "tag")
                            if isGenericLabel(label) {
                                Text("\(label) (\(confidence)) [EXCLU]")
                                    .foregroundColor(.red)
                            } else {
                                Text("\(label) (\(confidence))")
                            }
                        }
                    }
                    .disabled(true)
                }
                
                if !detectedLabels.isEmpty && (mainObjectLabel != nil || detectionSource != nil) {
                    Divider()
                }
                
                // Sujet principal
                if let mainLabel = mainObjectLabel {
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "viewfinder")
                            if isGenericLabel(mainLabel) {
                                if let confidence = mainObjectConfidence {
                                    Text("🎯 Sujet: \(mainLabel) (\(confidence)) [EXCLU]")
                                        .foregroundColor(.red)
                                } else {
                                    Text("🎯 Sujet: \(mainLabel) [EXCLU]")
                                        .foregroundColor(.red)
                                }
                            } else {
                                if let confidence = mainObjectConfidence {
                                    Text("🎯 Sujet: \(mainLabel) (\(confidence))")
                                } else {
                                    Text("🎯 Sujet: \(mainLabel)")
                                }
                            }
                        }
                    }
                    .disabled(true)
                }
                
                // Alternatives du sujet principal
                if !mainObjectAlternatives.isEmpty {
                    ForEach(mainObjectAlternatives, id: \.self) { alt in
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "arrow.turn.down.right")
                                if isGenericLabel(alt) {
                                    Text("↳ \(alt) [EXCLU]")
                                        .foregroundColor(.red)
                                } else {
                                    Text("↳ \(alt)")
                                }
                            }
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
                
                // Section Core Data
                if bestLabel != nil || !detectedLabels.isEmpty || detectionSource != nil {
                    Divider()
                }
                
                // Titre
                if let title = item.title, !title.isEmpty {
                    Button(action: {
                        UIPasteboard.general.string = title
                    }) {
                        Text("📝 Title: \(title)")
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                // Description
                if let description = item.itemDescription, !description.isEmpty {
                    Button(action: {
                        UIPasteboard.general.string = description
                    }) {
                        Text("📄 Description: \(description)")
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                // URL
                if let url = item.url, !url.isEmpty {
                    Button(action: {
                        UIPasteboard.general.string = url
                    }) {
                        Text("🔗 URL: \(url)")
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                // Content Type
                Button(action: {
                    UIPasteboard.general.string = item.contentTypeEnum.rawValue
                }) {
                    Label("🏷️ Type: \(item.contentTypeEnum.displayName)", systemImage: "tag.fill")
                }
                
                // ID
                Button(action: {
                    UIPasteboard.general.string = item.safeId.uuidString
                }) {
                    Label("🆔 ID: \(item.safeId.uuidString.prefix(8))...", systemImage: "number")
                }
                
                // Métadonnées complètes
                if !metadata.isEmpty {
                    Divider()
                    
                    ForEach(Array(metadata.keys.sorted().filter { key in
                        if let value = metadata[key] {
                            return !value.isEmpty
                        }
                        return false
                    }), id: \.self) { key in
                        Button(action: {
                            UIPasteboard.general.string = "\(key): \(metadata[key] ?? "")"
                        }) {
                            let value = metadata[key] ?? ""
                            Text("🔧 \(key): \(value)")
                                .lineLimit(nil)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
                
            } label: {
                Label("Vision Analysis (\(detectedLabels.count))", systemImage: "eye.fill")
            }
        }
        
        // Sous-menu OCR si du texte a été détecté - Affiché seulement en dev mode
        if userPreferences.devMode, let ocr = ocrText, !ocr.isEmpty {
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
        
            // Séparateur avant l'action de suppression
            Divider()
            
            // Action de suppression avec popup de confirmation
            Button(role: .destructive) {
                onDeleteRequest()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Actions
    
    private func reclassifyItem(to newType: ContentType) {
        withAnimation(.easeInOut(duration: 0.3)) {
            item.contentType = newType.rawValue
            item.updatedAt = Date()
        }
        
        // Forcer la notification des changements
        item.objectWillChange.send()
        
        contentService.updateContentItem(item)
    }
    
    private func buildShareContent() -> String {
        var content: [String] = []
        
        // Titre en premier
        if let title = item.title, !title.isEmpty, title != "Nouveau contenu" {
            content.append(title)
        }
        
        // Description
        if let description = item.itemDescription, !description.isEmpty {
            content.append(description)
        }
        
        // URL
        if let url = item.url, !url.isEmpty {
            content.append(url)
        }
        
        // Texte OCR si disponible
        if let ocr = ocrText, !ocr.isEmpty {
            content.append("Texte détecté: \(ocr)")
        }
        
        // Si rien d'autre, au moins la catégorie
        if content.isEmpty {
            content.append("Contenu de type: \(item.contentTypeEnum.displayName)")
        }
        
        return content.joined(separator: "\n\n")
    }
    
    private func shareContent() {
        var itemsToShare: [Any] = []
        
        // Ajouter l'image si disponible
        if let thumbnailUrl = item.thumbnailUrl, !thumbnailUrl.isEmpty {
            if thumbnailUrl.hasPrefix("file://") {
                // Fichier local - charger l'image depuis le disque
                if let localURL = URL(string: thumbnailUrl),
                   let imageData = try? Data(contentsOf: localURL),
                   let image = UIImage(data: imageData) {
                    itemsToShare.append(image)
                }
            } else {
                // URL distante - partager l'URL de l'image
                if let imageURL = URL(string: thumbnailUrl) {
                    itemsToShare.append(imageURL)
                }
            }
        }
        
        // Ajouter l'URL du contenu si disponible (seulement si ce n'est pas un fichier local)
        if let urlString = item.url, !urlString.isEmpty, !urlString.hasPrefix("file://") {
            if let url = URL(string: urlString) {
                itemsToShare.append(url)
            }
        }
        
        // Si rien, ajouter le texte
        if itemsToShare.isEmpty {
            itemsToShare.append(buildShareContent())
        }
        
        // Présenter le share sheet natif
        let activityVC = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    

}

// MARK: - Preview

#Preview {
    ContentItemContextMenu(
        item: ContentItem(),
        contentService: ContentServiceCoreData(),
        onStorageStatsRefresh: {},
        onDeleteRequest: {}
    )
}
