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
    private struct BackupCategory: Codable {
        let id: UUID
        let name: String
        let colorHex: String
        let iconName: String
        let sortOrder: Int32
        let isDefault: Bool
        let createdAt: Date
        let updatedAt: Date
    }
    
    private struct BackupItem: Codable {
        let id: UUID
        let userId: UUID?
        let categoryName: String?
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
        let categories: [BackupCategory]
        let items: [BackupItem]
    }
    
    
    // MARK: - Public API
    /// Exporte la base dans un dossier temporaire: items.json + fichiers images référencés dans thumbnailUrl
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
        
        // 1) Export JSON des catégories
        let categoriesFetch: NSFetchRequest<Category> = Category.fetchRequest()
        categoriesFetch.sortDescriptors = [NSSortDescriptor(keyPath: \Category.sortOrder, ascending: true)]
        let categories = try coreData.context.fetch(categoriesFetch)
        
        let mappedCategories: [BackupCategory] = categories.map { category in
            return BackupCategory(
                id: category.id ?? UUID(),
                name: category.name ?? "",
                colorHex: category.colorHex ?? "#007AFF",
                iconName: category.iconName ?? "folder",
                sortOrder: category.sortOrder,
                isDefault: category.isDefault,
                createdAt: category.createdAt ?? Date(),
                updatedAt: category.updatedAt ?? Date()
            )
        }
        
        // 2) Export JSON des items
        let itemsFetch: NSFetchRequest<ContentItem> = ContentItem.fetchRequest()
        itemsFetch.sortDescriptors = [NSSortDescriptor(keyPath: \ContentItem.createdAt, ascending: false)]
        let items = try coreData.context.fetch(itemsFetch)
        
        let mappedItems: [BackupItem] = items.map { item in
            let meta = (item.metadata as? [String: String]) ?? [:]
            return BackupItem(
                id: item.id ?? UUID(),
                userId: item.userId,
                categoryName: item.category?.name,
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
        let backup = BackupFile(version: 2, createdAt: Date(), categories: mappedCategories, items: mappedItems)
        let jsonURL = workingDir.appendingPathComponent("items.json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(backup)
        try jsonData.write(to: jsonURL, options: .atomic)
        
        // 3) Copier les images locales référencées (si existent)
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.misericode.pinpin") {
            for item in mappedItems {
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
        
        // 4) Retourner le dossier (le partage via Fichiers gère l'enregistrement du paquet)
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
        
        // Copier tout le dossier images/ dans le container partagé
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.misericode.pinpin") {
            let imagesSourceDir = root.appendingPathComponent("images", isDirectory: true)
            
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
                
                // Fallback: copier les images individuellement référencées dans les items
                for item in backup.items {
                    if let thumbnailUrl = item.thumbnailUrl, !thumbnailUrl.isEmpty, thumbnailUrl.hasPrefix("images/") {
                        let src = root.appendingPathComponent(thumbnailUrl)
                        let dst = containerURL.appendingPathComponent(thumbnailUrl)
                        // créer le dossier si nécessaire
                        try fm.createDirectory(at: dst.deletingLastPathComponent(), withIntermediateDirectories: true)
                        if fm.fileExists(atPath: dst.path) {
                            // ne pas écraser si déjà présent
                        } else if fm.fileExists(atPath: src.path) {
                            try fm.copyItem(at: src, to: dst)
                            print("[BackupService] Image individuelle importée: \(thumbnailUrl)")
                        }
                    }
                }
            }
        }
        
        // Import des catégories d'abord
        for bc in backup.categories {
            let req: NSFetchRequest<Category> = Category.fetchRequest()
            req.predicate = NSPredicate(format: "name == %@", bc.name)
            req.fetchLimit = 1
            let existing = try coreData.context.fetch(req).first
            let category: Category = existing ?? Category(context: coreData.context)
            
            category.id = bc.id
            category.name = bc.name
            category.colorHex = bc.colorHex
            category.iconName = bc.iconName
            category.sortOrder = bc.sortOrder
            category.isDefault = bc.isDefault
            category.createdAt = bc.createdAt
            category.updatedAt = bc.updatedAt
        }
        
        // Merge Core Data des items par id
        for bi in backup.items {
            let req: NSFetchRequest<ContentItem> = ContentItem.fetchRequest()
            req.predicate = NSPredicate(format: "id == %@", bi.id as CVarArg)
            req.fetchLimit = 1
            let existing = try coreData.context.fetch(req).first
            let item: ContentItem = existing ?? ContentItem(context: coreData.context)
            
            item.id = bi.id
            item.userId = bi.userId ?? item.userId
            
            // Associer la catégorie par nom
            if let categoryName = bi.categoryName {
                let categoryReq: NSFetchRequest<Category> = Category.fetchRequest()
                categoryReq.predicate = NSPredicate(format: "name == %@", categoryName)
                categoryReq.fetchLimit = 1
                if let category = try coreData.context.fetch(categoryReq).first {
                    item.category = category
                }
            }
            
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
}
