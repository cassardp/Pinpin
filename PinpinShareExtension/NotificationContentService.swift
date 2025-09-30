//
//  NotificationContentService.swift
//  PinpinShareExtension
//
//  Version simplifiée pour la Share Extension
//  Utilise des fichiers dans l'App Group au lieu des UserDefaults
//

import Foundation

struct NotificationContentService {
    
    // Constantes pour les fichiers de notification
    private enum Constants {
        static let groupID = "group.com.misericode.pinpin"
        static let pendingContentFileName = "pending_shared_contents.json"
        static let newContentFlagFileName = "has_new_content.flag"
    }
    
    /// Méthode statique pour sauvegarder un nouveau contenu depuis l'extension
    static func saveSharedContent(_ contentData: [String: Any]) {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Constants.groupID) else {
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
            
            // Convertir les Data en Base64 pour la sérialisation JSON
            var serializedContents: [[String: Any]] = []
            for content in pendingContents {
                var serializedContent = content
                
                // Convertir imageData en Base64 si présent
                if let imageData = content["imageData"] as? Data {
                    serializedContent["imageData"] = imageData.base64EncodedString()
                }
                
                serializedContents.append(serializedContent)
            }
            
            let jsonData = try JSONSerialization.data(withJSONObject: serializedContents, options: [])
            try jsonData.write(to: pendingContentURL)
            
            // Créer le flag de nouveau contenu
            try Data().write(to: flagURL)
            
            // Envoyer une notification Darwin pour réveiller l'app principale
            CFNotificationCenterPostNotification(
                CFNotificationCenterGetDarwinNotifyCenter(),
                CFNotificationName(rawValue: AppConstants.newContentNotificationName),
                nil,
                nil,
                true
            )
            
        } catch {
            // Erreur silencieuse - le partage continuera de fonctionner
        }
    }
    
    /// Vérifie s'il y a des contenus en attente
    static func hasPendingContents() -> Bool {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Constants.groupID) else {
            return false
        }
        
        let pendingContentURL = containerURL.appendingPathComponent(Constants.pendingContentFileName)
        return FileManager.default.fileExists(atPath: pendingContentURL.path)
    }
}
