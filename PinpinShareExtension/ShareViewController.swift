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

class ShareViewController: UIViewController {
    
    private var sharedContent: SharedContentData?
    private var isProcessingContent = false
    private var ocrMetadata: [String: String] = [:]
    
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
        
        // Traiter le premier attachment pertinent
        for attachment in attachments {
            // Priorité 1: URLs
            if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (item, error) in
                    if let url = item as? URL {
                        DispatchQueue.main.async {
                            self?.handleURL(url)
                        }
                    } else {
                        self?.completeRequest()
                    }
                }
                return
            }
        }
        
        // Priorité 2: Texte
        for attachment in attachments {
            if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] (item, error) in
                    if let text = item as? String {
                        DispatchQueue.main.async {
                            self?.handleText(text)
                        }
                    } else {
                        self?.completeRequest()
                    }
                }
                return
            }
        }
        
        // Priorité 3: Images
        for attachment in attachments {
            if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] (item, error) in
                    if let imageURL = item as? URL {
                        DispatchQueue.main.async {
                            self?.handleImageURL(imageURL)
                        }
                    } else {
                        self?.completeRequest()
                    }
                }
                return
            }
        }
        
        completeRequest()
    }
    
    private func handleURL(_ url: URL) {
        // Utiliser LinkPresentation pour obtenir les métadonnées de base
        let metadataProvider = LPMetadataProvider()
        metadataProvider.startFetchingMetadata(for: url) { [weak self] (metadata, error) in
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
            
            // Pas d'image, créer le contenu sans thumbnail
            self?.updateContentAfterProcessing(title: title, url: url.absoluteString, description: description, imageData: nil)
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
        // Utiliser LinkPresentation même pour les images (comme dans l'ancienne version)
        let metadataProvider = LPMetadataProvider()
        metadataProvider.startFetchingMetadata(for: imageURL) { [weak self] (metadata, error) in
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
            onCategorySelected: { [weak self] category in
                self?.saveContent(contentData, to: category)
            },
            onCancel: { [weak self] in
                self?.completeRequest()
            }
        )
        
        // Intégrer directement dans le ShareViewController au lieu d'une sheet
        let hostingController = UIHostingController(rootView: categoryModal)
        
        // Ajouter comme enfant du ShareViewController
        addChild(hostingController)
        view.addSubview(hostingController.view)
        
        // Contraintes pour remplir toute la vue
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        hostingController.didMove(toParent: self)
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
        // Utiliser le contenu final si disponible, sinon le contenu temporaire
        let finalContent = self.sharedContent ?? contentData
        
        var sharedContent: [String: Any] = [
            "category": category,
            "title": finalContent.title,
            "url": finalContent.url ?? "",
            "description": finalContent.description ?? "",
            "thumbnailUrl": finalContent.thumbnailPath ?? "",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // Ajouter les données d'image si disponibles
        if let imageData = finalContent.imageData {
            sharedContent["imageData"] = imageData
        }
        
        // Ajouter les métadonnées OCR si disponibles
        if !ocrMetadata.isEmpty {
            sharedContent["metadata"] = ocrMetadata
        }
        
        // Sauvegarder dans UserDefaults partagés
        if let sharedDefaults = UserDefaults(suiteName: "group.com.misericode.pinpin") {
            var pendingContents = sharedDefaults.array(forKey: "pendingSharedContents") as? [[String: Any]] ?? []
            pendingContents.append(sharedContent)
            sharedDefaults.set(pendingContents, forKey: "pendingSharedContents")
            sharedDefaults.set(true, forKey: "hasNewSharedContent")
            sharedDefaults.synchronize()
        }
        
        completeRequest()
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
            let optimizedData = self.optimizeImageForSwiftData(image)
            
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
    
    private func optimizeImageForSwiftData(_ image: UIImage) -> Data {
        // Si l'image fait moins de 1MB en qualité 0.8, la garder telle quelle
        var compressionQuality: CGFloat = 0.8
        var compressedData = image.jpegData(compressionQuality: compressionQuality) ?? Data()
        
        // Réduire la qualité jusqu'à obtenir moins de 1MB
        while compressedData.count > 1_000_000 && compressionQuality > 0.1 {
            compressionQuality -= 0.1
            compressedData = image.jpegData(compressionQuality: compressionQuality) ?? Data()
        }
        
        // Si toujours trop gros, redimensionner l'image
        if compressedData.count > 1_000_000 {
            let maxSize: CGFloat = 1024
            let size = image.size
            let ratio = min(maxSize / size.width, maxSize / size.height)
            
            if ratio < 1.0 {
                let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
                UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                image.draw(in: CGRect(origin: .zero, size: newSize))
                let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                if let resized = resizedImage {
                    compressedData = resized.jpegData(compressionQuality: 0.8) ?? compressedData
                }
            }
        }
        
        print("[ShareExtension] Image optimisée: \(compressedData.count) bytes")
        return compressedData
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
