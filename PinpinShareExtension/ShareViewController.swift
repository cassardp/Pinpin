//
//  ShareViewController.swift
//  PinpinShareExtension
//
//  Share Extension optimisée avec sauvegarde immédiate et enrichissement asynchrone
//

import UIKit
import UniformTypeIdentifiers
import LinkPresentation
import SwiftUI
import Vision
import SwiftData

class ShareViewController: UIViewController, ObservableObject {
    
    @Published var isSaved = false
    @Published var errorMessage: String?
    private var savedItemId: PersistentIdentifier?
    private var isSaving = false
    
    // SwiftData container partagé
    private lazy var modelContainer: ModelContainer = {
        let schema = Schema([ContentItem.self, Category.self])
        let configuration = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(AppConstants.groupID),
            cloudKitDatabase: .private(AppConstants.cloudKitContainerID)
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Impossible de créer ModelContainer dans l'extension: \(error)")
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.systemBackground
        embedSavingView()
        
        // Lancer le traitement optimisé
        processSharedContentOptimized()
    }
    
    // MARK: - Pipeline Optimisé
    
    private func processSharedContentOptimized() {
        guard let extensionContext = extensionContext,
              let extensionItem = extensionContext.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            completeRequest()
            return
        }
        
        // Étape 1: Extraire les données de base rapidement
        extractBasicContent(from: attachments) { [weak self] basicContent in
            guard let self = self, let content = basicContent else {
                self?.completeRequest()
                return
            }
            
            // Étape 2: Sauvegarder IMMÉDIATEMENT avec les données de base
            self.saveContentImmediately(content) { savedId in
                guard let itemId = savedId else {
                    // Erreur de sauvegarde
                    DispatchQueue.main.async {
                        self.errorMessage = "Erreur de sauvegarde"
                    }
                    self.completeRequestAfterDelay(0.5)
                    return
                }
                
                self.savedItemId = itemId
                
                // Étape 3: Afficher "Saved!" immédiatement
                DispatchQueue.main.async {
                    self.isSaved = true
                }
                
                // Étape 4: Enrichir en arrière-plan (métadonnées, image, OCR)
                self.enrichContentInBackground(content, itemId: itemId) {
                    // Fermer après enrichissement (ou timeout)
                    self.completeRequestAfterDelay(0.3)
                }
            }
        }
    }
    
    // MARK: - Extraction rapide des données de base
    
    private struct BasicContent {
        let title: String
        let url: String?
        let description: String?
        let originalURL: URL?
    }
    
    private func extractBasicContent(from attachments: [NSItemProvider], completion: @escaping (BasicContent?) -> Void) {
        // Priorité 1: URL
        if let attachment = attachments.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) {
            attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] item, _ in
                if let url = item as? URL {
                    let title = url.host ?? url.absoluteString
                    completion(BasicContent(title: title, url: url.absoluteString, description: nil, originalURL: url))
                } else {
                    self?.extractTextContent(from: attachments, completion: completion)
                }
            }
            return
        }
        
        // Priorité 2: Texte (peut contenir une URL)
        extractTextContent(from: attachments, completion: completion)
    }
    
    private func extractTextContent(from attachments: [NSItemProvider], completion: @escaping (BasicContent?) -> Void) {
        if let attachment = attachments.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }) {
            attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                if let text = item as? String {
                    // Vérifier si c'est une URL
                    if let url = self.extractURLFromText(text) {
                        let title = url.host ?? text
                        completion(BasicContent(title: title, url: url.absoluteString, description: nil, originalURL: url))
                    } else {
                        // Texte simple
                        completion(BasicContent(title: text, url: nil, description: text, originalURL: nil))
                    }
                } else {
                    completion(nil)
                }
            }
            return
        }
        
        // Priorité 3: Image
        if let attachment = attachments.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }) {
            attachment.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, _ in
                if let url = item as? URL {
                    let title = url.lastPathComponent
                    completion(BasicContent(title: title, url: url.absoluteString, description: nil, originalURL: url))
                } else {
                    completion(BasicContent(title: "Image", url: nil, description: nil, originalURL: nil))
                }
            }
            return
        }
        
        completion(nil)
    }
    
    // MARK: - Sauvegarde immédiate
    
    private func saveContentImmediately(_ content: BasicContent, completion: @escaping (PersistentIdentifier?) -> Void) {
        guard !isSaving else {
            completion(nil)
            return
        }
        isSaving = true
        
        Task { @MainActor in
            let context = modelContainer.mainContext
            
            do {
                // Vérifier les doublons récents
                let tenSecondsAgo = Date().addingTimeInterval(-10)
                let contentTitle = content.title
                let contentUrl = content.url
                
                let duplicateDescriptor = FetchDescriptor<ContentItem>(
                    predicate: #Predicate { item in
                        item.title == contentTitle &&
                        item.url == contentUrl &&
                        item.createdAt > tenSecondsAgo
                    }
                )
                
                if let existingItem = try context.fetch(duplicateDescriptor).first {
                    print("[ShareExtension] ⚠️ Doublon détecté, utilisation de l'item existant")
                    completion(existingItem.persistentModelID)
                    return
                }
                
                // Trouver ou créer la catégorie Misc
                let categoryName = AppConstants.defaultCategoryName
                let categoryDescriptor = FetchDescriptor<Category>(
                    predicate: #Predicate { $0.name == categoryName }
                )
                let category = try context.fetch(categoryDescriptor).first ?? {
                    let newCategory = Category(name: categoryName)
                    context.insert(newCategory)
                    return newCategory
                }()
                
                // Créer l'item avec données minimales
                let newItem = ContentItem(
                    title: content.title,
                    itemDescription: content.description,
                    url: content.url,
                    thumbnailUrl: nil,
                    imageData: nil,
                    metadata: nil,
                    category: category
                )
                
                context.insert(newItem)
                try context.save()
                
                print("[ShareExtension] ✅ Item sauvegardé rapidement: \(content.title)")
                completion(newItem.persistentModelID)
                
            } catch {
                print("[ShareExtension] ❌ Erreur sauvegarde: \(error)")
                completion(nil)
            }
        }
    }
    
    // MARK: - Enrichissement en arrière-plan
    
    private func enrichContentInBackground(_ content: BasicContent, itemId: PersistentIdentifier, completion: @escaping () -> Void) {
        guard let url = content.originalURL else {
            completion()
            return
        }
        
        let scopedAccess = beginSecurityScopedAccessIfNeeded(for: url)
        
        // Timeout pour l'enrichissement (max 5 secondes)
        let enrichmentGroup = DispatchGroup()
        var enrichmentCompleted = false
        
        enrichmentGroup.enter()
        
        // Lancer l'enrichissement
        let metadataProvider = LPMetadataProvider()
        metadataProvider.startFetchingMetadata(for: url) { [weak self] metadata, error in
            defer {
                self?.endSecurityScopedAccessIfNeeded(for: url, started: scopedAccess)
            }
            
            guard let self = self else {
                enrichmentGroup.leave()
                return
            }
            
            var enrichedTitle: String?
            var imageData: Data?
            var ocrMetadata: [String: String] = [:]
            
            if let metadata = metadata, error == nil {
                if let title = metadata.title, !title.isEmpty {
                    enrichedTitle = title
                }
                
                // Récupérer l'image
                if let imageProvider = metadata.imageProvider {
                    let imageGroup = DispatchGroup()
                    imageGroup.enter()
                    
                    imageProvider.loadObject(ofClass: UIImage.self) { object, _ in
                        defer { imageGroup.leave() }
                        
                        guard let image = object as? UIImage else { return }
                        
                        // Optimiser l'image
                        imageData = ImageOptimizationService.shared.optimize(image)
                        
                        // OCR (synchrone pour simplifier)
                        let ocrGroup = DispatchGroup()
                        ocrGroup.enter()
                        OCRService.shared.extractText(from: image) { ocrText in
                            if let text = ocrText, !text.isEmpty {
                                ocrMetadata["ocr_text"] = OCRService.shared.cleanOCRText(text)
                            }
                            ocrGroup.leave()
                        }
                        ocrGroup.wait()
                    }
                    
                    imageGroup.wait()
                }
            }
            
            // Mettre à jour l'item avec les enrichissements
            self.updateItemWithEnrichments(
                itemId: itemId,
                title: enrichedTitle,
                imageData: imageData,
                metadata: ocrMetadata
            )
            
            enrichmentGroup.leave()
        }
        
        // Timeout de 5 secondes
        DispatchQueue.global().async {
            let result = enrichmentGroup.wait(timeout: .now() + 5.0)
            if result == .timedOut {
                print("[ShareExtension] ⚠️ Enrichissement timeout, fermeture")
            }
            if !enrichmentCompleted {
                enrichmentCompleted = true
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }
    
    private func updateItemWithEnrichments(itemId: PersistentIdentifier, title: String?, imageData: Data?, metadata: [String: String]) {
        Task { @MainActor in
            let context = modelContainer.mainContext
            
            guard let item = context.model(for: itemId) as? ContentItem else {
                print("[ShareExtension] ❌ Item non trouvé pour enrichissement")
                return
            }
            
            // Mettre à jour les champs enrichis
            if let title = title, !title.isEmpty {
                item.title = title
            }
            
            if let imageData = imageData {
                item.imageData = imageData
            }
            
            if !metadata.isEmpty {
                item.metadata = try? JSONEncoder().encode(metadata)
            }
            
            do {
                try context.save()
                print("[ShareExtension] ✅ Item enrichi avec succès")
            } catch {
                print("[ShareExtension] ⚠️ Erreur enrichissement: \(error)")
            }
        }
    }
    
    // MARK: - Utility Methods
    
    private func extractURLFromText(_ text: String) -> URL? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        return matches?.first?.url
    }
    
    private func completeRequest() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    private func completeRequestAfterDelay(_ delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.isSaving = false
            self?.completeRequest()
        }
    }
    
    private func beginSecurityScopedAccessIfNeeded(for url: URL) -> Bool {
        guard url.isFileURL else { return false }
        return url.startAccessingSecurityScopedResource()
    }
    
    private func endSecurityScopedAccessIfNeeded(for url: URL, started: Bool) {
        guard started else { return }
        url.stopAccessingSecurityScopedResource()
    }
}

// MARK: - UI Embedding

private extension ShareViewController {
    func embedSavingView() {
        let hostingController = UIHostingController(rootView: SavingViewWrapper(controller: self))
        
        addChild(hostingController)
        self.view.addSubview(hostingController.view)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
        
        hostingController.didMove(toParent: self)
    }
}

// MARK: - Saving Views

private struct SavingViewWrapper: View {
    @ObservedObject var controller: ShareViewController
    
    var body: some View {
        SavingView(isSaved: controller.isSaved, errorMessage: controller.errorMessage)
    }
}

private struct SavingView: View {
    var isSaved: Bool
    var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            if let error = errorMessage {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.red)
                    .transition(.scale.combined(with: .opacity))
                
                Text(error)
                    .font(.headline)
                    .foregroundColor(.primary)
            } else if isSaved {
                Image("PinpinLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    .transition(.scale.combined(with: .opacity))
                
                Text("Saved to Pinpin")
                    .font(.headline)
                    .foregroundColor(.primary)
            } else {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text("Saving...")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
        .ignoresSafeArea()
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSaved)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: errorMessage)
    }
}
