//
//  ShareViewController.swift
//  NeeedShareExtension
//
//  Share Extension pour l'app Neeed - Partage instantané sans popup
//

import UIKit
import UniformTypeIdentifiers
import LinkPresentation

class ShareViewController: UIViewController {
    
    private var toastView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Afficher le toast de capture
        showCapturingToast()
        
        // Ajouter un délai pour améliorer la capture des métadonnées
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.processSharedContent()
        }
    }
    
    private func processSharedContent() {
        guard let extensionContext = extensionContext,
              let extensionItem = extensionContext.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            completeRequest()
            return
        }
        
        // Traiter seulement le premier attachment pertinent (comportement natif)
        for attachment in attachments {
            // Priorité 1: URLs (le plus important)
            if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (item, error) in
                    if let url = item as? URL {
                        self?.handleURL(url) {
                            self?.completeRequest()
                        }
                    } else {
                        self?.completeRequest()
                    }
                }
                return // Traiter seulement le premier URL trouvé
            }
        }
        
        // Priorité 2: Texte (si pas d'URL)
        for attachment in attachments {
            if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] (item, error) in
                    if let text = item as? String {
                        self?.handleText(text) {
                            self?.completeRequest()
                        }
                    } else {
                        self?.completeRequest()
                    }
                }
                return // Traiter seulement le premier texte trouvé
            }
        }
        
        // Priorité 3: Images (si pas d'URL ni texte)
        for attachment in attachments {
            if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] (item, error) in
                    if let imageURL = item as? URL {
                        self?.handleImageURL(imageURL) {
                            self?.completeRequest()
                        }
                    } else {
                        self?.completeRequest()
                    }
                }
                return // Traiter seulement la première image trouvée
            }
        }
        
        // Aucun attachment reconnu
        completeRequest()
    }
    
    private func handleURL(_ url: URL, completion: @escaping () -> Void) {
        let contentType = ContentTypeDetector.shared.detectContentType(from: url)
        
        // Utiliser LinkPresentation pour obtenir les métadonnées système (plus fiable)
        let metadataProvider = LPMetadataProvider()
        metadataProvider.startFetchingMetadata(for: url) { [weak self] (metadata, error) in
            var extractedMetadata: [String: String] = [:]
            var finalTitle = url.absoluteString
            let finalDescription: String? = nil
            
            if let metadata = metadata, error == nil {
                // Extraire les métadonnées LinkPresentation
                if let title = metadata.title, !title.isEmpty {
                    extractedMetadata["best_title"] = title
                    finalTitle = title
                }
                
                if let url = metadata.originalURL?.absoluteString {
                    extractedMetadata["original_url"] = url
                }
                
                // Extraire l'image/icône
                if let imageProvider = metadata.imageProvider {
                    // Sauvegarder l'image dans le dossier partagé
                    self?.saveImageFromProvider(imageProvider) { imagePath in
                        if let imagePath = imagePath {
                            extractedMetadata["thumbnail_url"] = imagePath
                            extractedMetadata["has_local_image"] = "true"
                        }
                        
                        // Maintenant essayer de capturer l'icône aussi
                        if let iconProvider = metadata.iconProvider {
                            self?.saveImageFromProvider(iconProvider) { iconPath in
                                if let iconPath = iconPath {
                                    extractedMetadata["icon_url"] = iconPath
                                    extractedMetadata["has_local_icon"] = "true"
                                }
                                
                                // Sauvegarder avec les métadonnées LinkPresentation
                                DispatchQueue.main.async {
                                    self?.saveSharedContent(
                                        type: contentType,
                                        title: finalTitle,
                                        url: url.absoluteString,
                                        description: finalDescription,
                                        metadata: extractedMetadata
                                    )
                                    completion()
                                }
                            }
                        } else {
                            // Pas d'icône, sauvegarder quand même
                            DispatchQueue.main.async {
                                self?.saveSharedContent(
                                    type: contentType,
                                    title: finalTitle,
                                    url: url.absoluteString,
                                    description: finalDescription,
                                    metadata: extractedMetadata
                                )
                                completion()
                            }
                        }
                    }
                    return
                }
                
                // Extraire l'icône si pas d'image principale
                if let iconProvider = metadata.iconProvider {
                    self?.saveImageFromProvider(iconProvider) { iconPath in
                        if let iconPath = iconPath {
                            extractedMetadata["icon_url"] = iconPath
                            extractedMetadata["has_local_icon"] = "true"
                        }
                        
                        // Sauvegarder avec les métadonnées LinkPresentation
                        DispatchQueue.main.async {
                            self?.saveSharedContent(
                                type: contentType,
                                title: finalTitle,
                                url: url.absoluteString,
                                description: finalDescription,
                                metadata: extractedMetadata
                            )
                            completion()
                        }
                    }
                    return
                }
            }
            
            // Si LinkPresentation n'a pas d'image/icône, sauvegarder quand même
            DispatchQueue.main.async {
                self?.saveSharedContent(
                    type: contentType,
                    title: finalTitle,
                    url: url.absoluteString,
                    description: finalDescription,
                    metadata: extractedMetadata
                )
                completion()
            }
        }
    }
    
    private func handleText(_ text: String, completion: @escaping () -> Void) {
        // Détecter les URLs dans le texte
        if let detectedURL = extractURLFromText(text) {
            // Si on trouve une URL, la traiter avec LinkPresentation
            handleURL(detectedURL, completion: completion)
        } else {
            // Sinon, traiter comme texte simple
            saveSharedContent(
                type: "text",
                title: text,
                url: nil,
                description: text,
                metadata: nil
            )
            
            // Appeler completion de manière asynchrone pour s'assurer que la sauvegarde est terminée
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    private func handleImageURL(_ imageURL: URL, completion: @escaping () -> Void) {
        let contentType = "image"
        
        // Utiliser LinkPresentation même pour les images
        let metadataProvider = LPMetadataProvider()
        metadataProvider.startFetchingMetadata(for: imageURL) { [weak self] (metadata, error) in
            var extractedMetadata: [String: String] = [:]
            var finalTitle = imageURL.lastPathComponent
            let finalDescription: String? = nil
            
            if let metadata = metadata, error == nil {
                if let title = metadata.title, !title.isEmpty {
                    extractedMetadata["best_title"] = title
                    finalTitle = title
                }
                
                // Extraire l'image
                if let imageProvider = metadata.imageProvider {
                    self?.saveImageFromProvider(imageProvider) { imagePath in
                        if let imagePath = imagePath {
                            extractedMetadata["thumbnail_url"] = imagePath
                            extractedMetadata["has_local_image"] = "true"
                        }
                        
                        // Maintenant essayer de capturer l'icône aussi
                        if let iconProvider = metadata.iconProvider {
                            self?.saveImageFromProvider(iconProvider) { iconPath in
                                if let iconPath = iconPath {
                                    extractedMetadata["icon_url"] = iconPath
                                    extractedMetadata["has_local_icon"] = "true"
                                }
                                
                                DispatchQueue.main.async {
                                    self?.saveSharedContent(
                                        type: contentType,
                                        title: finalTitle,
                                        url: imageURL.absoluteString,
                                        description: finalDescription,
                                        metadata: extractedMetadata
                                    )
                                    completion()
                                }
                            }
                        } else {
                            // Pas d'icône, sauvegarder quand même
                            DispatchQueue.main.async {
                                self?.saveSharedContent(
                                    type: contentType,
                                    title: finalTitle,
                                    url: imageURL.absoluteString,
                                    description: finalDescription,
                                    metadata: extractedMetadata
                                )
                                completion()
                            }
                        }
                    }
                    return
                }
            }
            
            // Si pas de métadonnées, sauvegarder quand même
            DispatchQueue.main.async {
                self?.saveSharedContent(
                    type: contentType,
                    title: finalTitle,
                    url: imageURL.absoluteString,
                    description: finalDescription,
                    metadata: extractedMetadata
                )
                completion()
            }
        }
    }
    
    private func saveSharedContent(type: String, title: String, url: String?, description: String?, metadata: [String: String]?) {
        let sharedContent: [String: Any] = [
            "type": type,
            "title": title,
            "url": url ?? "",
            "description": description ?? "",
            "metadata": metadata ?? [:],
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // Méthode 1: UserDefaults partagés (simplifié)
        if let sharedDefaults = UserDefaults(suiteName: "group.com.misericode.pinpin") {
            var pendingContents = sharedDefaults.array(forKey: "pendingSharedContents") as? [[String: Any]] ?? []
            pendingContents.append(sharedContent)
            sharedDefaults.set(pendingContents, forKey: "pendingSharedContents")
            
            // Activer le flag de nouveau contenu
            sharedDefaults.set(true, forKey: "hasNewSharedContent")
            sharedDefaults.synchronize()
        }
        
        // Méthode 2: Fichier partagé (backup)
        saveToSharedFile(content: sharedContent)
    }
    
    private func saveToSharedFile(content: [String: Any]) {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.misericode.pinpin") else {
            return
        }
        
        let fileURL = containerURL.appendingPathComponent("pendingContents.json")
        
        do {
            var existingContents: [[String: Any]] = []
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let data = try Data(contentsOf: fileURL)
                existingContents = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
            }
            
            existingContents.append(content)
            
            let data = try JSONSerialization.data(withJSONObject: existingContents)
            try data.write(to: fileURL)
        } catch {
        }
    }
    
    private func saveImageFromProvider(_ imageProvider: NSItemProvider, completion: @escaping (String?) -> Void) {
        // Vérifier si c'est une image
        guard imageProvider.canLoadObject(ofClass: UIImage.self) else {
            completion(nil)
            return
        }
        
        imageProvider.loadObject(ofClass: UIImage.self) { (object, error) in
            guard let image = object as? UIImage,
                  let imageData = image.jpegData(compressionQuality: 0.8) else {
                completion(nil)
                return
            }
            
            // Sauvegarder dans le dossier partagé
            guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.misericode.pinpin") else {
                completion(nil)
                return
            }
            
            let imagesDirectory = containerURL.appendingPathComponent("images")
            
            // Créer le dossier images s'il n'existe pas
            do {
                try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
            } catch {
                completion(nil)
                return
            }
            
            // Nom de fichier unique
            let fileName = "\(UUID().uuidString).jpg"
            let fileURL = imagesDirectory.appendingPathComponent(fileName)
            
            do {
                try imageData.write(to: fileURL)
                // Retourner le chemin relatif pour l'app principale
                completion("images/\(fileName)")
            } catch {
                completion(nil)
            }
        }
    }
    
    private func completeRequest() {
        // Masquer le toast
        toastView?.removeFromSuperview()
        
        // Fermer l'extension
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    private func showCapturingToast() {
        // Créer la vue toast discrète
        toastView = UIView()
        toastView?.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        toastView?.layer.cornerRadius = 16
        toastView?.layer.masksToBounds = true
        
        // Ajouter une ombre subtile
        toastView?.layer.shadowColor = UIColor.black.cgColor
        toastView?.layer.shadowOffset = CGSize(width: 0, height: 2)
        toastView?.layer.shadowOpacity = 0.1
        toastView?.layer.shadowRadius = 4
        toastView?.layer.masksToBounds = false
        
        // Ajouter le texte
        let label = UILabel()
        label.text = "Please wait"
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = UIColor.white
        label.textAlignment = .center
        
        toastView?.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: (toastView?.centerXAnchor)!).isActive = true
        label.centerYAnchor.constraint(equalTo: (toastView?.centerYAnchor)!).isActive = true
        
        // Ajouter la vue toast en haut de l'écran
        view.addSubview(toastView!)
        toastView?.translatesAutoresizingMaskIntoConstraints = false
        toastView?.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16).isActive = true
        toastView?.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        toastView?.widthAnchor.constraint(equalToConstant: 110).isActive = true
        toastView?.heightAnchor.constraint(equalToConstant: 32).isActive = true
        
        // Animation d'apparition subtile
        toastView?.alpha = 0
        toastView?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: {
            self.toastView?.alpha = 1
            self.toastView?.transform = CGAffineTransform.identity
        })
    }
    
    // MARK: - URL Detection Helper
    
    private func extractURLFromText(_ text: String) -> URL? {
        // Utiliser NSDataDetector pour détecter les URLs de façon robuste
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        // Prendre la première URL trouvée
        if let match = matches?.first,
           let range = Range(match.range, in: text) {
            let urlString = String(text[range])
            
            // Vérifier si c'est une URL valide
            if let url = URL(string: urlString), url.scheme != nil {
                return url
            }
            
            // Si pas de schéma, essayer d'ajouter https://
            if let url = URL(string: "https://\(urlString)") {
                return url
            }
        }
        
        return nil
    }
}
