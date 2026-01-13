//
//  SharedContentService.swift
//  Pinpin
//
//  Service pour gérer les contenus partagés via Share Extension
//  Utilise Core Data au lieu de Supabase
//

import Foundation

class SharedContentService: ObservableObject {
    private let contentService: ContentServiceCoreData
    
    // Flag pour détecter les nouveaux contenus
    private static let newContentFlagKey = "hasNewSharedContent"
    
    // Notifications
    static let darwinNotificationName = "com.misericode.pinpin.newSharedContent"
    static let localNotificationName = Notification.Name("LocalNewSharedContentNotification")
    
    init(contentService: ContentServiceCoreData) {
        self.contentService = contentService
        startObservingDarwinNotifications()
    }
    
    deinit {
        stopObservingDarwinNotifications()
    }
    
    func processPendingSharedContents() async {
        // Toujours recréer l'instance pour éviter le cache stale sur Mac
        let sharedDefaults = UserDefaults(suiteName: "group.com.misericode.pinpin")
        
        // Force sync to ensure we see the latest data from the extension
        sharedDefaults?.synchronize()
        
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
        guard let category = contentData["category"] as? String,
              let title = contentData["title"] as? String else {
            print("[SharedContentService] Erreur: données invalides pour le contenu")
            return
        }
        
        print("[SharedContentService] Traitement contenu: \(category) - \(title)")
        
        let url = contentData["url"] as? String
        let description = contentData["description"] as? String
        let thumbnailUrl = contentData["thumbnailUrl"] as? String
        let metadata = contentData["metadata"] as? [String: String] ?? [:]
        
        // Charger les données de l'image si disponbile
        var imageData: Data?
        if let relativePath = thumbnailUrl, !relativePath.isEmpty {
            if let imageURL = SharedImageService.shared.getImageURL(from: relativePath) {
                do {
                    imageData = try Data(contentsOf: imageURL)
                    print("[SharedContentService] Image chargée (\(imageData?.count ?? 0) bytes) depuis: \(relativePath)")
                } catch {
                     print("[SharedContentService] Erreur lecture image: \(error)")
                }
            }
        }

        // Create immutable copy for thread safety
        let finalImageData = imageData

        // Sauvegarder directement avec Core Data
        await MainActor.run {
            contentService.saveContentItem(
                categoryName: category,
                title: title,
                description: description,
                url: url,
                metadata: metadata,
                thumbnailUrl: thumbnailUrl,
                imageData: finalImageData
            )
            
            print("[SharedContentService] Contenu '\(category)' sauvegardé avec succès")
        }
    }
    
    func hasPendingSharedContents() -> Bool {
        let sharedDefaults = UserDefaults(suiteName: "group.com.misericode.pinpin")
        guard let pendingContents = sharedDefaults?.array(forKey: "pendingSharedContents") as? [[String: Any]] else {
            return false
        }
        return !pendingContents.isEmpty
    }
    
    // MARK: - Flag System
    
    /// Vérifie s'il y a du nouveau contenu partagé
    func hasNewSharedContent() -> Bool {
        let sharedDefaults = UserDefaults(suiteName: "group.com.misericode.pinpin")
        // Force sync
        sharedDefaults?.synchronize()
        return sharedDefaults?.bool(forKey: Self.newContentFlagKey) ?? false
    }
    
    /// Réinitialise le flag de nouveau contenu
    private func clearNewContentFlag() {
        let sharedDefaults = UserDefaults(suiteName: "group.com.misericode.pinpin")
        sharedDefaults?.set(false, forKey: Self.newContentFlagKey)
        sharedDefaults?.synchronize()
    }
    
    /// Méthode appelée par l'extension pour signaler un nouveau contenu
    static func setNewContentFlag() {
        let sharedDefaults = UserDefaults(suiteName: "group.com.misericode.pinpin")
        sharedDefaults?.set(true, forKey: newContentFlagKey)
        sharedDefaults?.synchronize()
    }
    
    // MARK: - Darwin Notifications
    
    private func startObservingDarwinNotifications() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        CFNotificationCenterAddObserver(center, observer, { center, observer, name, object, userInfo in
            // Ce callback est C-style, on doit revenir vers Swift
            DispatchQueue.main.async {
                 // Traiter directement les données sans attendre la Vue
                Task {
                    let service = Unmanaged<SharedContentService>.fromOpaque(observer!).takeUnretainedValue()
                    await service.processPendingSharedContents()
                    
                    // Notifier quand même pour l'UI si besoin
                    NotificationCenter.default.post(name: SharedContentService.localNotificationName, object: nil)
                }
            }
        }, Self.darwinNotificationName as CFString, nil, .deliverImmediately)
        
        print("[SharedContentService] Observation des notifications Darwin démarrée")
    }
    
    private func stopObservingDarwinNotifications() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
        CFNotificationCenterRemoveObserver(center, observer, CFNotificationName(rawValue: Self.darwinNotificationName as CFString), nil)
    }
}
