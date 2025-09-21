//
//  BackupService.swift
//  Pinpin
//
//  Simple native backup/export & import for Core Data items + local images
//

import Foundation
import CoreData
import UniformTypeIdentifiers

@MainActor
final class BackupService: ObservableObject {
    static let shared = BackupService()
    private init() {}
    
    private let coreData = CoreDataService.shared
    
    // MARK: - Backup model
    private struct BackupItem: Codable {
        let id: UUID
        let userId: UUID?
        let contentType: String
        let title: String
        let itemDescription: String?
        let url: String?
        let metadata: [String: String]
        let thumbnailUrl: String?
        let isHidden: Bool
        let createdAt: Date?
        let updatedAt: Date?
    }
    
    private struct BackupFile: Codable {
        let version: Int
        let createdAt: Date
        let items: [BackupItem]
    }
    
    // MARK: - Legacy format support (temporaire)
    private struct LegacyBackupItem: Codable {
        let id: String
        let userId: String?
        let contentType: String
        let title: String
        let itemDescription: String?
        let url: String?
        let metadata: [String: String]
        let isHidden: Bool
        let createdAt: String?
        let updatedAt: String?
    }
    
    private struct LegacyBackupFile: Codable {
        let version: Int
        let createdAt: String
        let items: [LegacyBackupItem]
    }
    
    // MARK: - Public API
    /// Exporte la base dans un dossier temporaire: items.json + fichiers images référencés dans metadata (thumbnail_url, icon_url)
    func exportBackupZip() throws -> URL {
        let fm = FileManager.default
        let tmpRoot = fm.temporaryDirectory
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let stamp = formatter.string(from: Date())
        let workingDir = tmpRoot.appendingPathComponent("PinpinBackup_\(stamp)", isDirectory: true)
        try fm.createDirectory(at: workingDir, withIntermediateDirectories: true)
        
        // 1) Export JSON des items
        let fetch: NSFetchRequest<ContentItem> = ContentItem.fetchRequest()
        fetch.sortDescriptors = [NSSortDescriptor(keyPath: \ContentItem.createdAt, ascending: false)]
        let items = try coreData.context.fetch(fetch)
        
        let mapped: [BackupItem] = items.map { item in
            let meta = (item.metadata as? [String: String]) ?? [:]
            return BackupItem(
                id: item.id ?? UUID(),
                userId: item.userId,
                contentType: item.contentType ?? "",
                title: item.title ?? "Untitled",
                itemDescription: item.itemDescription,
                url: item.url,
                metadata: meta,
                thumbnailUrl: item.thumbnailUrl,
                isHidden: item.isHidden,
                createdAt: item.createdAt,
                updatedAt: item.updatedAt
            )
        }
        let backup = BackupFile(version: 1, createdAt: Date(), items: mapped)
        let jsonURL = workingDir.appendingPathComponent("items.json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(backup)
        try jsonData.write(to: jsonURL, options: .atomic)
        
        // 2) Copier les images locales référencées (si existent)
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.misericode.pinpin") {
            for item in mapped {
                // Utiliser uniquement thumbnailUrl (nouveau système simplifié)
                if let thumbnailUrl = item.thumbnailUrl, !thumbnailUrl.isEmpty, thumbnailUrl.hasPrefix("images/") {
                    let src = containerURL.appendingPathComponent(thumbnailUrl)
                    if fm.fileExists(atPath: src.path) {
                        let dst = workingDir.appendingPathComponent(thumbnailUrl)
                        try fm.createDirectory(at: dst.deletingLastPathComponent(), withIntermediateDirectories: true)
                        if fm.fileExists(atPath: dst.path) {
                            try? fm.removeItem(at: dst)
                        }
                        try fm.copyItem(at: src, to: dst)
                        print("[BackupService] Image copiée: \(thumbnailUrl)")
                    }
                }
            }
        }
        
        // 3) Retourner le dossier (le partage via Fichiers gère l'enregistrement du paquet)
        return workingDir
    }
    
    /// Importe un dossier d'export Pinpin: merge par id, copie les images dans le container App Group
    func importBackup(from url: URL) throws {
        let fm = FileManager.default
        let root: URL = url
        // Autoriser l'accès aux ressources sécurisées (Files app)
        let didStartAccess = root.startAccessingSecurityScopedResource()
        defer { if didStartAccess { root.stopAccessingSecurityScopedResource() } }
        // Import dossier uniquement; zip non supporté
        if url.pathExtension.lowercased() == "zip" {
            throw NSError(domain: "BackupService", code: 2, userInfo: [NSLocalizedDescriptionKey: "ZIP import is not supported. Select the backup folder."])
        }
        
        // items.json doit être à la racine du dossier de sauvegarde
        var jsonURL = root.appendingPathComponent("items.json")
        if !fm.fileExists(atPath: jsonURL.path) {
            // Fallback: chercher récursivement si l'utilisateur a sélectionné un dossier parent par erreur
            if let enumerator = fm.enumerator(at: root, includingPropertiesForKeys: nil),
               let found = enumerator.compactMap({ $0 as? URL }).first(where: { $0.lastPathComponent == "items.json" }) {
                jsonURL = found
            } else {
                throw NSError(domain: "BackupService", code: 1, userInfo: [NSLocalizedDescriptionKey: "items.json not found at backup root"])
            }
        }
        // iCloud: forcer le téléchargement si nécessaire
        if fm.isUbiquitousItem(at: jsonURL) {
            try? fm.startDownloadingUbiquitousItem(at: jsonURL)
        }
        let data = try Data(contentsOf: jsonURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(BackupFile.self, from: data)
        
        // Copier images dans le container partagé
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.misericode.pinpin") {
            for item in backup.items {
                // Utiliser uniquement thumbnailUrl (nouveau système simplifié)
                if let thumbnailUrl = item.thumbnailUrl, !thumbnailUrl.isEmpty, thumbnailUrl.hasPrefix("images/") {
                    let src = root.appendingPathComponent(thumbnailUrl)
                    let dst = containerURL.appendingPathComponent(thumbnailUrl)
                    // créer le dossier si nécessaire
                    try fm.createDirectory(at: dst.deletingLastPathComponent(), withIntermediateDirectories: true)
                    if fm.fileExists(atPath: dst.path) {
                        // ne pas écraser si déjà présent
                    } else if fm.fileExists(atPath: src.path) {
                        try fm.copyItem(at: src, to: dst)
                        print("[BackupService] Image importée: \(thumbnailUrl)")
                    }
                }
            }
        }
        
        // Merge Core Data par id
        for bi in backup.items {
            let req: NSFetchRequest<ContentItem> = ContentItem.fetchRequest()
            req.predicate = NSPredicate(format: "id == %@", bi.id as CVarArg)
            req.fetchLimit = 1
            let existing = try coreData.context.fetch(req).first
            let item: ContentItem = existing ?? ContentItem(context: coreData.context)
            
            item.id = bi.id
            item.userId = bi.userId ?? item.userId
            item.contentType = bi.contentType
            item.title = bi.title
            item.itemDescription = bi.itemDescription
            item.url = bi.url
            item.metadata = bi.metadata as NSDictionary
            item.thumbnailUrl = bi.thumbnailUrl
            item.isHidden = bi.isHidden
            item.createdAt = bi.createdAt ?? item.createdAt
            item.updatedAt = Date()
        }
        coreData.save()
    }
    
    // MARK: - Legacy Import (temporaire)
    /// Importe un fichier JSON de l'ancien format de sauvegarde + images du dossier
    func importLegacyBackup(from url: URL) throws {
        let fm = FileManager.default
        
        // Autoriser l'accès aux ressources sécurisées
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer { if didStartAccess { url.stopAccessingSecurityScopedResource() } }
        
        // Déterminer le dossier racine de la sauvegarde
        let backupRoot: URL
        if url.pathExtension.lowercased() == "json" {
            // Si c'est un fichier JSON, le dossier parent est la racine
            backupRoot = url.deletingLastPathComponent()
        } else {
            // Si c'est un dossier, c'est la racine directement
            backupRoot = url
        }
        
        // Chercher le fichier JSON dans le dossier
        let jsonURL: URL
        if url.pathExtension.lowercased() == "json" {
            jsonURL = url
        } else {
            // Chercher items.json dans le dossier
            let candidateJSON = backupRoot.appendingPathComponent("items.json")
            if fm.fileExists(atPath: candidateJSON.path) {
                jsonURL = candidateJSON
            } else {
                throw NSError(domain: "BackupService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Fichier items.json introuvable dans le dossier de sauvegarde"])
            }
        }
        
        // Lire et décoder le fichier JSON
        let data = try Data(contentsOf: jsonURL)
        let decoder = JSONDecoder()
        let legacyBackup = try decoder.decode(LegacyBackupFile.self, from: data)
        
        print("[BackupService] Import legacy backup avec \(legacyBackup.items.count) items depuis \(backupRoot.path)")
        
        // Convertir et importer chaque item
        let dateFormatter = ISO8601DateFormatter()
        
        for legacyItem in legacyBackup.items {
            // Vérifier si l'item existe déjà
            guard let itemId = UUID(uuidString: legacyItem.id) else {
                print("[BackupService] ID invalide ignoré: \(legacyItem.id)")
                continue
            }
            
            let req: NSFetchRequest<ContentItem> = ContentItem.fetchRequest()
            req.predicate = NSPredicate(format: "id == %@", itemId as CVarArg)
            req.fetchLimit = 1
            let existing = try coreData.context.fetch(req).first
            
            // Ne pas écraser les items existants
            if existing != nil {
                print("[BackupService] Item déjà existant ignoré: \(legacyItem.id)")
                continue
            }
            
            // Créer un nouvel item
            let item = ContentItem(context: coreData.context)
            item.id = itemId
            item.userId = legacyItem.userId.flatMap { UUID(uuidString: $0) }
            item.contentType = legacyItem.contentType
            item.title = legacyItem.title
            item.itemDescription = legacyItem.itemDescription
            item.url = legacyItem.url
            item.metadata = legacyItem.metadata as NSDictionary
            item.isHidden = legacyItem.isHidden
            
            // Convertir les dates depuis les strings ISO8601
            if let createdAtString = legacyItem.createdAt {
                item.createdAt = dateFormatter.date(from: createdAtString)
            }
            if let updatedAtString = legacyItem.updatedAt {
                item.updatedAt = dateFormatter.date(from: updatedAtString)
            } else {
                item.updatedAt = Date()
            }
            
            // Extraire thumbnailUrl depuis metadata si présent
            if let thumbnailUrl = legacyItem.metadata["thumbnail_url"], !thumbnailUrl.isEmpty {
                item.thumbnailUrl = thumbnailUrl
            }
            
            print("[BackupService] Item importé: \(legacyItem.title)")
        }
        
        // Importer les images du dossier images/ vers le container App Group
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.misericode.pinpin") {
            let imagesSourceDir = backupRoot.appendingPathComponent("images", isDirectory: true)
            
            if fm.fileExists(atPath: imagesSourceDir.path) {
                print("[BackupService] Import des images depuis \(imagesSourceDir.path)")
                
                // Créer le dossier images dans le container si nécessaire
                let imagesDestDir = containerURL.appendingPathComponent("images", isDirectory: true)
                try fm.createDirectory(at: imagesDestDir, withIntermediateDirectories: true)
                
                // Énumérer tous les fichiers dans le dossier images/
                if let enumerator = fm.enumerator(at: imagesSourceDir, includingPropertiesForKeys: [.isRegularFileKey]) {
                    var importedCount = 0
                    var skippedCount = 0
                    
                    for case let fileURL as URL in enumerator {
                        // Vérifier que c'est un fichier (pas un dossier)
                        let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey])
                        guard resourceValues?.isRegularFile == true else { continue }
                        
                        // Calculer le chemin relatif depuis le dossier images/
                        let relativePath = fileURL.path.replacingOccurrences(of: imagesSourceDir.path + "/", with: "")
                        let destURL = imagesDestDir.appendingPathComponent(relativePath)
                        
                        // Créer les dossiers intermédiaires si nécessaire
                        try fm.createDirectory(at: destURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                        
                        // Copier le fichier s'il n'existe pas déjà
                        if fm.fileExists(atPath: destURL.path) {
                            skippedCount += 1
                            // print("[BackupService] Image déjà existante ignorée: \(relativePath)")
                        } else {
                            try fm.copyItem(at: fileURL, to: destURL)
                            importedCount += 1
                            print("[BackupService] Image importée: \(relativePath)")
                        }
                    }
                    
                    print("[BackupService] Images importées: \(importedCount), ignorées: \(skippedCount)")
                }
            } else {
                print("[BackupService] Aucun dossier images/ trouvé dans la sauvegarde")
            }
        }
        
        coreData.save()
        print("[BackupService] Import legacy terminé avec succès")
    }
}
