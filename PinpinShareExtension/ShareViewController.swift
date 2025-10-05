//
//  ShareViewController.swift
//  PinpinShareExtension
//
//  Share Extension simplifiée avec sélection de catégorie
//

import UIKit
import UniformTypeIdentifiers
import LinkPresentation
import SwiftUI
import Vision
import SwiftData

class ShareViewController: UIViewController, ObservableObject {
    
    private var sharedContent: SharedContentData?
    @Published var isProcessingContent = false
    private var ocrMetadata: [String: String] = [:]
    
    // SwiftData container partagé (recommandation Apple)
    private lazy var modelContainer: ModelContainer = {
        let schema = Schema([ContentItem.self, Category.self])
        let configuration = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(AppConstants.groupID),
            cloudKitDatabase: .automatic // Utilise le container iCloud principal des entitlements
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
        
        // Afficher l'interface immédiatement avec un contenu temporaire
        showCategorySelectionImmediately()
        
        // Traiter le contenu partagé en arrière-plan
        processSharedContentInBackground()
    }
    
    private func showCategorySelectionImmediately() {
        // Créer un contenu temporaire pour afficher l'interface immédiatement
        let temporaryContent = SharedContentData(
            title: "Loading...",
            url: nil,
            description: "Processing shared content..."
        )
        
        showCategorySelection(for: temporaryContent)
    }
    
    private func processSharedContentInBackground() {
        isProcessingContent = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.processSharedContent()
        }
    }
    
    private func processSharedContent() {
        guard let extensionContext = extensionContext,
              let extensionItem = extensionContext.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            completeRequest()
            return
        }
        
        if loadItem(from: attachments, type: .url, transform: { $0 as? URL }, handler: { [weak self] url in
            self?.handleURL(url)
        }) {
            return
        }
        
        if loadItem(from: attachments, type: .plainText, transform: { $0 as? String }, handler: { [weak self] text in
            self?.handleText(text)
        }) {
            return
        }
        
        if loadItem(from: attachments, type: .image, transform: { $0 as? URL }, handler: { [weak self] imageURL in
            self?.handleImageURL(imageURL)
        }) {
            return
        }
        
        completeRequest()
    }
    
    private func handleURL(_ url: URL) {
        let scopedAccess = beginSecurityScopedAccessIfNeeded(for: url)
        // Utiliser LinkPresentation pour obtenir les métadonnées de base
        let metadataProvider = LPMetadataProvider()
        metadataProvider.startFetchingMetadata(for: url) { [weak self] (metadata, error) in
            defer {
                self?.endSecurityScopedAccessIfNeeded(for: url, started: scopedAccess)
            }
            var title = url.absoluteString
            let description: String? = nil
            
            if let metadata = metadata, error == nil {
                if let metadataTitle = metadata.title, !metadataTitle.isEmpty {
                    title = metadataTitle
                }
                
                // Sauvegarder l'image si disponible (pas d'icônes)
                if let imageProvider = metadata.imageProvider {
                    self?.saveImageFromProvider(imageProvider, extraMetadataHandler: { ocrMetadata in
                        // Stocker les métadonnées OCR pour utilisation ultérieure
                        self?.storeOCRMetadata(ocrMetadata)
                    }) { imageData in
                        self?.updateContentAfterProcessing(title: title, url: url.absoluteString, description: description, imageData: imageData)
                    }
                    return
                }
            }
            
            // Pas d'image via LinkPresentation, essayer le fallback
            self?.tryFallbackImageRetrieval(for: url, title: title, description: description)
        }
    }
    
    private func handleText(_ text: String) {
        // Détecter les URLs dans le texte
        if let detectedURL = extractURLFromText(text) {
            handleURL(detectedURL)
        } else {
            // Traiter comme texte simple
            updateContentAfterProcessing(title: text, url: nil, description: text, imageData: nil)
        }
    }
    
    private func handleImageURL(_ imageURL: URL) {
        let scopedAccess = beginSecurityScopedAccessIfNeeded(for: imageURL)
        // Utiliser LinkPresentation même pour les images (comme dans l'ancienne version)
        let metadataProvider = LPMetadataProvider()
        metadataProvider.startFetchingMetadata(for: imageURL) { [weak self] (metadata, error) in
            defer {
                self?.endSecurityScopedAccessIfNeeded(for: imageURL, started: scopedAccess)
            }
            var finalTitle = imageURL.lastPathComponent
            let finalDescription: String? = nil
            
            if let metadata = metadata, error == nil {
                if let title = metadata.title, !title.isEmpty {
                    finalTitle = title
                }
                
                // Extraire l'image
                if let imageProvider = metadata.imageProvider {
                    // Save main image and merge analysis metadata
                    self?.saveImageFromProvider(imageProvider, extraMetadataHandler: { ocrMetadata in
                        // Stocker les métadonnées OCR pour utilisation ultérieure
                        self?.storeOCRMetadata(ocrMetadata)
                    }) { imageData in
                        self?.updateContentAfterProcessing(title: finalTitle, url: imageURL.absoluteString, description: finalDescription, imageData: imageData)
                    }
                    return
                }
            }
            
            // Si pas de métadonnées, sauvegarder quand même
            self?.updateContentAfterProcessing(title: finalTitle, url: imageURL.absoluteString, description: finalDescription, imageData: nil)
        }
    }
    
    // MARK: - Category Selection Modal
    
    private func showCategorySelection(for contentData: SharedContentData) {
        self.sharedContent = contentData
        
        let categoryModal = CategorySelectionModalWrapper(
            contentData: contentData,
            isProcessing: .constant(isProcessingContent),
            onCategorySelected: { [weak self] category in
                self?.saveContent(contentData, to: category)
            },
            onCancel: { [weak self] in
                self?.completeRequest()
            }
        )
        embedCategorySelectionView(categoryModal)
    }
    
    private func updateContentAfterProcessing(title: String, url: String?, description: String?, imageData: Data?) {
        let finalContentData = SharedContentData(
            title: title,
            url: url,
            description: description,
            thumbnailPath: nil, // Plus utilisé avec SwiftData
            imageData: imageData
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.sharedContent = finalContentData
            self?.isProcessingContent = false
            // L'interface est déjà affichée, pas besoin de la recréer
        }
    }
    
    private func saveContent(_ contentData: SharedContentData, to category: String) {
        // Si le traitement est encore en cours, attendre qu'il se termine
        if isProcessingContent {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.saveContent(contentData, to: category)
            }
            return
        }

        // Utiliser le contenu final si disponible, sinon le contenu temporaire
        let finalContent = self.sharedContent ?? contentData

        // Sauvegarder via repositories
        Task { @MainActor in
            let context = modelContainer.mainContext
            let categoryRepo = CategoryRepository(context: context)
            let contentRepo = ContentItemRepository(context: context)

            do {
                // Vérifier si un item identique a été créé récemment (évite les doublons lors de taps rapides)
                if let existingItem = try contentRepo.fetchRecentDuplicate(
                    title: finalContent.title,
                    url: finalContent.url,
                    withinSeconds: 2.0
                ) {
                    print("[ShareExtension] ⚠️ Item identique trouvé (créé il y a \(Date().timeIntervalSince(existingItem.createdAt))s), skip")
                    self.completeRequest()
                    return
                }

                // Trouver ou créer la catégorie via repository
                let categoryObject = try categoryRepo.findOrCreate(name: category)

                // Créer le ContentItem
                let newItem = ContentItem(
                    title: finalContent.title,
                    itemDescription: finalContent.description,
                    url: finalContent.url,
                    thumbnailUrl: finalContent.thumbnailPath,
                    imageData: finalContent.imageData,
                    metadata: self.encodeMetadata(self.ocrMetadata),
                    category: categoryObject
                )

                contentRepo.insert(newItem)

                // Sauvegarder
                try context.save()
                print("[ShareExtension] ✅ Item sauvegardé dans SwiftData")
            } catch {
                print("[ShareExtension] ❌ Erreur sauvegarde: \(error)")
            }

            self.completeRequest()
        }
    }
    
    private func encodeMetadata(_ metadata: [String: String]) -> Data? {
        guard !metadata.isEmpty else { return nil }
        return try? JSONEncoder().encode(metadata)
    }
    
    
    private func saveImageFromProvider(_ imageProvider: NSItemProvider,
                                       extraMetadataHandler: (([String: String]) -> Void)? = nil,
                                       completion: @escaping (Data?) -> Void) {
        print("[ShareExtension] Début sauvegarde image en Data")
        
        // Vérifier si c'est une image
        guard imageProvider.canLoadObject(ofClass: UIImage.self) else {
            print("[ShareExtension] Erreur: imageProvider ne peut pas charger UIImage")
            completion(nil)
            return
        }
        
        print("[ShareExtension] ImageProvider peut charger UIImage, chargement...")
        
        imageProvider.loadObject(ofClass: UIImage.self) { (object, error) in
            if let error = error {
                print("[ShareExtension] Erreur lors du chargement de l'image: \(error)")
                completion(nil)
                return
            }
            
            guard let image = object as? UIImage else {
                print("[ShareExtension] Erreur: impossible de convertir en UIImage")
                completion(nil)
                return
            }
            
            // Optimiser l'image pour SwiftData (max 1MB)
            let optimizedData = ImageOptimizationService.shared.optimize(image)
            
            print("[ShareExtension] Image optimisée avec succès, taille: \(optimizedData.count) bytes")
            
            // Lancer l'OCR automatique sur l'image
            self.performOCROnImage(image) { ocrText in
                var metadata: [String: String] = [:]
                
                if let ocrText = ocrText, !ocrText.isEmpty {
                    let cleanedText = OCRService.shared.cleanOCRText(ocrText)
                    metadata["ocr_text"] = cleanedText
                    print("[ShareExtension] OCR extrait: \(cleanedText)")
                }
                
                // Appeler le handler de métadonnées si fourni
                extraMetadataHandler?(metadata)
                
                // Retourner les données de l'image directement
                completion(optimizedData)
            }
        }
    }
    
    
    // MARK: - Fallback Image Retrieval
    
    private func tryFallbackImageRetrieval(for url: URL, title: String, description: String?) {
        print("[ShareExtension] Tentative de récupération d'image via fallback pour: \(url)")
        
        LinkMetadataFallbackService.shared.fetchImageFallback(from: url) { [weak self] image in
            if let image = image {
                print("[ShareExtension] Image récupérée via fallback")
                // Optimiser l'image et lancer l'OCR
                let optimizedData = ImageOptimizationService.shared.optimize(image)
                
                self?.performOCROnImage(image) { ocrText in
                    var metadata: [String: String] = [:]
                    
                    if let ocrText = ocrText, !ocrText.isEmpty {
                        let cleanedText = OCRService.shared.cleanOCRText(ocrText)
                        metadata["ocr_text"] = cleanedText
                        print("[ShareExtension] OCR fallback extrait: \(cleanedText)")
                    }
                    
                    self?.storeOCRMetadata(metadata)
                    self?.updateContentAfterProcessing(title: title, url: url.absoluteString, description: description, imageData: optimizedData)
                }
            } else {
                print("[ShareExtension] Échec du fallback, contenu sans image")
                // Aucune image trouvée, créer le contenu sans thumbnail
                self?.updateContentAfterProcessing(title: title, url: url.absoluteString, description: description, imageData: nil)
            }
        }
    }
    
    // MARK: - OCR Methods
    
    private func performOCROnImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        OCRService.shared.extractText(from: image) { ocrText in
            DispatchQueue.main.async {
                completion(ocrText)
            }
        }
    }
    
    private func storeOCRMetadata(_ metadata: [String: String]) {
        // Fusionner les nouvelles métadonnées OCR avec les existantes
        for (key, value) in metadata {
            ocrMetadata[key] = value
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
}

// MARK: - Helpers
private extension ShareViewController {
    func loadItem<T>(from attachments: [NSItemProvider], type: UTType, transform: @escaping (NSSecureCoding?) -> T?, handler: @escaping (T) -> Void) -> Bool {
        for attachment in attachments {
            if attachment.hasItemConformingToTypeIdentifier(type.identifier) {
                attachment.loadItem(forTypeIdentifier: type.identifier, options: nil) { [weak self] item, _ in
                    guard let value = transform(item) else {
                        self?.completeRequest()
                        return
                    }
                    DispatchQueue.main.async {
                        handler(value)
                    }
                }
                return true
            }
        }
        return false
    }
    
    func embedCategorySelectionView(_ view: CategorySelectionModalWrapper) {
        let hostingController = UIHostingController(rootView: view)
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
    
    func beginSecurityScopedAccessIfNeeded(for url: URL) -> Bool {
        guard url.isFileURL else { return false }
        return url.startAccessingSecurityScopedResource()
    }
    
    func endSecurityScopedAccessIfNeeded(for url: URL, started: Bool) {
        guard started else { return }
        url.stopAccessingSecurityScopedResource()
    }
}
