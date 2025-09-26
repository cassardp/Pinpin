//
//  NotificationContentService.swift
//  Pinpin
//
//  Service pour gérer les notifications entre l'app et l'extension
//  Utilise des fichiers dans l'App Group au lieu des UserDefaults
//

import Foundation

@MainActor
final class NotificationContentService: ObservableObject {
    private let dataService: DataService
    private let fileManager = FileManager.default
    
    // Constantes pour les fichiers de notification
    private enum Constants {
        static let groupID = "group.com.misericode.pinpin"
        static let pendingContentFileName = "pending_shared_contents.json"
        static let newContentFlagFileName = "has_new_content.flag"
    }
    
    // URLs des fichiers dans l'App Group
    private lazy var containerURL: URL? = {
        return fileManager.containerURL(forSecurityApplicationGroupIdentifier: Constants.groupID)
    }()
    
    private lazy var pendingContentURL: URL? = {
        return containerURL?.appendingPathComponent(Constants.pendingContentFileName)
    }()
    
    private lazy var newContentFlagURL: URL? = {
        return containerURL?.appendingPathComponent(Constants.newContentFlagFileName)
    }()
    
    init(dataService: DataService) {
        self.dataService = dataService
    }
    
    // MARK: - Gestion des contenus en attente
    
    func processPendingSharedContents() async {
        guard let pendingContentURL = pendingContentURL else { return }
        
        // Vérifier s'il y a des contenus en attente
        guard fileManager.fileExists(atPath: pendingContentURL.path) else {
            clearNewContentFlag()
            return
        }
        
        do {
            // Lire les contenus en attente
            let data = try Data(contentsOf: pendingContentURL)
            let rawPendingContents = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
            
            guard !rawPendingContents.isEmpty else {
                clearNewContentFlag()
                return
            }
            
            // Reconvertir les Base64 en Data
            var pendingContents: [[String: Any]] = []
            for content in rawPendingContents {
                var processedContent = content
                
                // Reconvertir imageData depuis Base64 si présent
                if let base64String = content["imageData"] as? String,
                   let imageData = Data(base64Encoded: base64String) {
                    processedContent["imageData"] = imageData
                }
                
                pendingContents.append(processedContent)
            }
            
            // Traiter chaque contenu
            for contentData in pendingContents {
                await processSharedContent(contentData)
            }
            
            // Nettoyer les fichiers traités
            try fileManager.removeItem(at: pendingContentURL)
            clearNewContentFlag()
            
        } catch {
            // Erreur silencieuse - le système continuera de fonctionner
        }
    }
    
    private func processSharedContent(_ contentData: [String: Any]) async {
        guard let category = contentData["category"] as? String,
              let title = contentData["title"] as? String else {
            return
        }
        
        let url = contentData["url"] as? String
        let description = contentData["description"] as? String
        let thumbnailUrl = contentData["thumbnailUrl"] as? String
        let imageData = contentData["imageData"] as? Data
        let metadata = contentData["metadata"] as? [String: String] ?? [:]
        
        // Sauvegarder avec SwiftData
        dataService.saveContentItemWithImageData(
            categoryName: category,
            title: title,
            description: description,
            url: url,
            metadata: metadata,
            thumbnailUrl: thumbnailUrl,
            imageData: imageData
        )
    }
    
    // MARK: - Gestion du flag de nouveau contenu
    
    func hasNewSharedContent() -> Bool {
        guard let flagURL = newContentFlagURL else { return false }
        return fileManager.fileExists(atPath: flagURL.path)
    }
    
    private func clearNewContentFlag() {
        guard let flagURL = newContentFlagURL else { return }
        try? fileManager.removeItem(at: flagURL)
    }
    
    
    // MARK: - Méthodes statiques pour l'extension
    
    /// Méthode appelée par l'extension pour sauvegarder un nouveau contenu
    static func saveSharedContent(_ contentData: [String: Any]) {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Constants.groupID) else {
            print("[NotificationContentService] ❌ Impossible d'accéder au container partagé")
            return
        }
        
        let pendingContentURL = containerURL.appendingPathComponent(Constants.pendingContentFileName)
        let flagURL = containerURL.appendingPathComponent(Constants.newContentFlagFileName)
        
        do {
            // Lire les contenus existants ou créer un nouveau tableau
            var pendingContents: [[String: Any]] = []
            if FileManager.default.fileExists(atPath: pendingContentURL.path) {
                let existingData = try Data(contentsOf: pendingContentURL)
                pendingContents = try JSONSerialization.jsonObject(with: existingData) as? [[String: Any]] ?? []
            }
            
            // Ajouter le nouveau contenu
            pendingContents.append(contentData)
            
            // Sauvegarder le fichier mis à jour
            let jsonData = try JSONSerialization.data(withJSONObject: pendingContents, options: [])
            try jsonData.write(to: pendingContentURL)
            
            // Créer le flag de nouveau contenu
            try Data().write(to: flagURL)
            
            print("[NotificationContentService] ✅ Contenu sauvegardé dans le fichier partagé")
            
        } catch {
            print("[NotificationContentService] ❌ Erreur lors de la sauvegarde: \(error)")
        }
    }
    
    /// Vérifie s'il y a des contenus en attente (pour l'extension)
    static func hasPendingContents() -> Bool {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Constants.groupID) else {
            return false
        }
        
        let pendingContentURL = containerURL.appendingPathComponent(Constants.pendingContentFileName)
        return FileManager.default.fileExists(atPath: pendingContentURL.path)
    }
}
