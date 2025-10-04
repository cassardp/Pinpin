//
//  BackupService.swift
//  Pinpin
//
//  Service de sauvegarde/restauration native pour les données SwiftData + images locales
//

import Foundation
import SwiftData
import UniformTypeIdentifiers

@MainActor
final class BackupService: ObservableObject {
    static let shared = BackupService()
    private init() {}
    
    private let dataService = DataService.shared
    
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
        let hasImage: Bool // Indique si l'item a une image (fichier séparé)
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
        let categories = dataService.fetchCategories()
        
        let mappedCategories: [BackupCategory] = categories.map { category in
            return BackupCategory(
                id: category.id,
                name: category.name,
                colorHex: category.colorHex,
                iconName: category.iconName,
                sortOrder: category.sortOrder,
                isDefault: category.isDefault,
                createdAt: category.createdAt,
                updatedAt: category.updatedAt
            )
        }
        
        // 2) Export JSON des items
        let items = dataService.loadContentItems()
        
        let mappedItems: [BackupItem] = items.map { item in
            // Convertir les métadonnées Data en dictionnaire
            var meta: [String: String] = [:]
            if let metadataData = item.metadata {
                do {
                    if let dict = try JSONSerialization.jsonObject(with: metadataData) as? [String: Any] {
                        meta = dict.compactMapValues { value in
                            if let stringValue = value as? String {
                                return stringValue
                            } else {
                                return String(describing: value)
                            }
                        }
                    }
                } catch {
                    print("Erreur lors de la conversion des métadonnées: \(error)")
                }
            }
            
            return BackupItem(
                id: item.id,
                userId: item.userId,
                categoryName: item.category?.name,
                title: item.title,
                itemDescription: item.itemDescription,
                url: item.url,
                metadata: meta,
                thumbnailUrl: item.thumbnailUrl,
                hasImage: item.imageData != nil, // Indiquer si l'item a une image
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
        
        // 3) Exporter les images SwiftData vers le dossier images/
        let imagesDir = workingDir.appendingPathComponent("images", isDirectory: true)
        try fm.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        
        var exportedImageCount = 0
        
        for item in items {
            if let imageData = item.imageData {
                // Utiliser l'ID de l'item comme nom de fichier
                let imageFileName = "\(item.id.uuidString).jpg"
                let imageURL = imagesDir.appendingPathComponent(imageFileName)
                
                try imageData.write(to: imageURL)
                exportedImageCount += 1
                print("[BackupService] Image exportée: \(imageFileName)")
            }
        }
        
        if exportedImageCount > 0 {
            print("[BackupService] \(exportedImageCount) images exportées dans le dossier images/")
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
        
        // Importer les images depuis le dossier images/
        let imagesDir = root.appendingPathComponent("images", isDirectory: true)
        var importedImageCount = 0
        
        if fm.fileExists(atPath: imagesDir.path) {
            print("[BackupService] Import des images depuis le dossier images/")
        }
        
        // Import des catégories d'abord via repository
        let categoryRepo = CategoryRepository(context: dataService.context)
        for bc in backup.categories {
            do {
                _ = try categoryRepo.upsert(
                    id: bc.id,
                    name: bc.name,
                    colorHex: bc.colorHex,
                    iconName: bc.iconName,
                    sortOrder: bc.sortOrder,
                    isDefault: bc.isDefault,
                    createdAt: bc.createdAt,
                    updatedAt: bc.updatedAt
                )
            } catch {
                print("Erreur lors de l'import de la catégorie \(bc.name): \(error)")
            }
        }
        
        // Merge SwiftData des items par id via repository
        let contentRepo = ContentItemRepository(context: dataService.context)
        for bi in backup.items {
            do {
                // Convertir les métadonnées en Data
                var metadataData: Data?
                if !bi.metadata.isEmpty {
                    metadataData = try? JSONSerialization.data(withJSONObject: bi.metadata)
                }

                // Restaurer l'image depuis le fichier si elle existe
                var imageData: Data?
                if bi.hasImage {
                    let imageFileName = "\(bi.id.uuidString).jpg"
                    let imageURL = imagesDir.appendingPathComponent(imageFileName)

                    if fm.fileExists(atPath: imageURL.path) {
                        do {
                            imageData = try Data(contentsOf: imageURL)
                            importedImageCount += 1
                            print("[BackupService] Image importée: \(imageFileName)")
                        } catch {
                            print("[BackupService] Erreur import image \(imageFileName): \(error)")
                        }
                    } else {
                        print("[BackupService] Image manquante: \(imageFileName)")
                    }
                }

                // Upsert via repository
                let item = try contentRepo.upsert(
                    id: bi.id,
                    userId: bi.userId,
                    categoryName: bi.categoryName,
                    title: bi.title,
                    itemDescription: bi.itemDescription,
                    url: bi.url,
                    metadata: metadataData,
                    thumbnailUrl: bi.thumbnailUrl,
                    imageData: imageData,
                    isHidden: bi.isHidden,
                    createdAt: bi.createdAt,
                    updatedAt: bi.updatedAt
                )

                // Associer la catégorie par nom
                if let categoryName = bi.categoryName {
                    if let category = try categoryRepo.fetchByName(categoryName) {
                        contentRepo.updateCategory(item, category: category)
                    }
                }
            } catch {
                print("Erreur lors de l'import de l'item \(bi.id): \(error)")
            }
        }
        
        if importedImageCount > 0 {
            print("[BackupService] Import terminé: \(importedImageCount) images importées")
        }
        
        dataService.save()
    }
}
