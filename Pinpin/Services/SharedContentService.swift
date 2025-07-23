//
//  SharedContentService.swift
//  Neeed2
//
//  Service pour gérer les contenus partagés via Share Extension
//  Utilise Core Data au lieu de Supabase
//

import Foundation

class SharedContentService: ObservableObject {
    private let sharedDefaults = UserDefaults(suiteName: "group.com.misericode.pinpin")
    private let contentService: ContentServiceCoreData
    
    // Flag pour détecter les nouveaux contenus
    private static let newContentFlagKey = "hasNewSharedContent"
    
    init(contentService: ContentServiceCoreData) {
        self.contentService = contentService
    }
    
    func processPendingSharedContents() async {
        guard let pendingContents = sharedDefaults?.array(forKey: "pendingSharedContents") as? [[String: Any]],
              !pendingContents.isEmpty else {
            // Réinitialiser le flag même s'il n'y a rien à traiter
            print("[SharedContentService] Aucun contenu en attente")
            clearNewContentFlag()
            return
        }
        
        print("[SharedContentService] Traitement de \(pendingContents.count) contenu(s) en attente")
        
        for contentData in pendingContents {
            await processSharedContent(contentData)
        }
        
        // Nettoyer les contenus traités et le flag
        sharedDefaults?.removeObject(forKey: "pendingSharedContents")
        clearNewContentFlag()
        sharedDefaults?.synchronize()
    }
    
    private func processSharedContent(_ contentData: [String: Any]) async {
        guard let typeString = contentData["type"] as? String,
              let contentType = ContentType(rawValue: typeString),
              let title = contentData["title"] as? String else {
            print("[SharedContentService] Erreur: données invalides pour le contenu")
            return
        }
        
        print("[SharedContentService] Traitement contenu: \(typeString) - \(title)")
        
        let url = contentData["url"] as? String
        let description = contentData["description"] as? String
        let metadata = contentData["metadata"] as? [String: String]
        let thumbnailUrl = contentData["thumbnailUrl"] as? String
        
        // Sauvegarder directement avec Core Data
        await MainActor.run {
            contentService.saveContentItem(
                contentType: contentType,
                title: title,
                description: description,
                url: url,
                metadata: metadata,
                thumbnailUrl: thumbnailUrl
            )
        }
    }
    
    func hasPendingSharedContents() -> Bool {
        guard let pendingContents = sharedDefaults?.array(forKey: "pendingSharedContents") as? [[String: Any]] else {
            return false
        }
        return !pendingContents.isEmpty
    }
    
    // MARK: - Flag System
    
    /// Vérifie s'il y a du nouveau contenu partagé
    func hasNewSharedContent() -> Bool {
        return sharedDefaults?.bool(forKey: Self.newContentFlagKey) ?? false
    }
    
    /// Réinitialise le flag de nouveau contenu
    private func clearNewContentFlag() {
        sharedDefaults?.set(false, forKey: Self.newContentFlagKey)
    }
    
    /// Méthode appelée par l'extension pour signaler un nouveau contenu
    static func setNewContentFlag() {
        let sharedDefaults = UserDefaults(suiteName: "group.com.misericode.pinpin")
        sharedDefaults?.set(true, forKey: newContentFlagKey)
        sharedDefaults?.synchronize()
    }
}
