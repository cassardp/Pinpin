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

class ShareViewController: UIViewController {
    
    private var sharedContent: SharedContentData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.systemBackground
        
        // Traiter le contenu partagé
        processSharedContent()
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
                    self?.saveImageFromProvider(imageProvider, extraMetadataHandler: { meta in
                        // Pas de métadonnées supplémentaires dans la version simplifiée
                    }) { imagePath in
                        if let imagePath = imagePath {
                            self?.createContentAndShowModal(title: title, url: url.absoluteString, description: description, thumbnailPath: imagePath)
                        } else {
                            self?.createContentAndShowModal(title: title, url: url.absoluteString, description: description, thumbnailPath: nil)
                        }
                    }
                    return
                }
            }
            
            // Pas d'image, créer le contenu sans thumbnail
            self?.createContentAndShowModal(title: title, url: url.absoluteString, description: description, thumbnailPath: nil)
        }
    }
    
    private func handleText(_ text: String) {
        // Détecter les URLs dans le texte
        if let detectedURL = extractURLFromText(text) {
            handleURL(detectedURL)
        } else {
            // Traiter comme texte simple
            let contentData = SharedContentData(
                title: text,
                url: nil,
                description: text
            )
            showCategorySelection(for: contentData)
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
                    self?.saveImageFromProvider(imageProvider, extraMetadataHandler: { meta in
                        // Pas de métadonnées supplémentaires
                    }) { imagePath in
                        if let imagePath = imagePath {
                            self?.createContentAndShowModal(title: finalTitle, url: imageURL.absoluteString, description: finalDescription, thumbnailPath: imagePath)
                        } else {
                            self?.createContentAndShowModal(title: finalTitle, url: imageURL.absoluteString, description: finalDescription, thumbnailPath: nil)
                        }
                    }
                    return
                }
            }
            
            // Si pas de métadonnées, sauvegarder quand même
            self?.createContentAndShowModal(title: finalTitle, url: imageURL.absoluteString, description: finalDescription, thumbnailPath: nil)
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
        
        let hostingController = UIHostingController(rootView: categoryModal)
        hostingController.modalPresentationStyle = .pageSheet
        
        if let sheet = hostingController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.selectedDetentIdentifier = .large
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.prefersEdgeAttachedInCompactHeight = true
        }
        
        present(hostingController, animated: true)
    }
    
    private func saveContent(_ contentData: SharedContentData, to category: String) {
        let sharedContent: [String: Any] = [
            "category": category,
            "title": contentData.title,
            "url": contentData.url ?? "",
            "description": contentData.description ?? "",
            "thumbnailUrl": contentData.thumbnailPath ?? "",
            "timestamp": Date().timeIntervalSince1970
        ]
        
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
    
    private func createContentAndShowModal(title: String, url: String, description: String?, thumbnailPath: String?) {
        let contentData = SharedContentData(
            title: title,
            url: url,
            description: description,
            thumbnailPath: thumbnailPath
        )
        
        DispatchQueue.main.async {
            self.showCategorySelection(for: contentData)
        }
    }
    
    private func saveImageFromProvider(_ imageProvider: NSItemProvider,
                                       extraMetadataHandler: (([String: String]) -> Void)? = nil,
                                       completion: @escaping (String?) -> Void) {
        print("[ShareExtension] Début sauvegarde image")
        
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
            
            guard let image = object as? UIImage,
                  let imageData = image.jpegData(compressionQuality: 0.8) else {
                print("[ShareExtension] Erreur: impossible de convertir en UIImage ou JPEG")
                completion(nil)
                return
            }
            
            print("[ShareExtension] Image chargée avec succès, taille: \(imageData.count) bytes")
            
            // Sauvegarder dans le dossier partagé
            guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.misericode.pinpin") else {
                print("[ShareExtension] Erreur: impossible d'accéder au container partagé")
                completion(nil)
                return
            }
            
            print("[ShareExtension] Container URL: \(containerURL)")
            
            let imagesDirectory = containerURL.appendingPathComponent("images")
            
            // Créer le dossier images s'il n'existe pas
            do {
                try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
                print("[ShareExtension] Dossier images créé: \(imagesDirectory)")
            } catch {
                print("[ShareExtension] Erreur création dossier: \(error)")
                completion(nil)
                return
            }
            
            // Nom de fichier unique
            let fileName = "\(UUID().uuidString).jpg"
            let fileURL = imagesDirectory.appendingPathComponent(fileName)
            
            print("[ShareExtension] Tentative d'écriture: \(fileURL)")
            
            do {
                try imageData.write(to: fileURL)
                print("[ShareExtension] Image sauvegardée avec succès: \(fileURL)")
                // Retourner le chemin relatif pour l'app principale
                completion("images/\(fileName)")
            } catch {
                print("[ShareExtension] Erreur écriture fichier: \(error)")
                completion(nil)
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
}
