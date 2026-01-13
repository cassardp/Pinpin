//
//  SharedImageService.swift
//  Pinpin
//
//  Service pour gérer les images sauvegardées par l'extension de partage
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
import CoreData

class SharedImageService {
    static let shared = SharedImageService()
    
    private init() {}
    
    /// Obtenir l'URL complète d'une image locale depuis le chemin relatif
    func getImageURL(from relativePath: String) -> URL? {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.misericode.pinpin") else {
            return nil
        }
        
        return containerURL.appendingPathComponent(relativePath)
    }
    
    /// Vérifier si une image locale existe
    func imageExists(at relativePath: String) -> Bool {
        guard let imageURL = getImageURL(from: relativePath) else {
            return false
        }
        
        return FileManager.default.fileExists(atPath: imageURL.path)
    }
    
    /// Supprimer les images associées à un ContentItem
    func deleteImagesForItem(_ item: ContentItem) {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.misericode.pinpin") else {
            print("❌ Impossible d'accéder au container partagé")
            return
        }
        
        print("🗑️ Suppression des images pour item: \(item.title ?? "Sans titre")")
        
        var deletedFiles = 0
        
        // Supprimer l'image principale si elle existe (nouveau système)
        if let thumbnailUrl = item.thumbnailUrl, !thumbnailUrl.isEmpty, thumbnailUrl.hasPrefix("images/") {
            let imageURL = containerURL.appendingPathComponent(thumbnailUrl)
            print("🖼️ Tentative de suppression de l'image: \(thumbnailUrl)")
            do {
                try FileManager.default.removeItem(at: imageURL)
                print("✅ Image supprimée: \(thumbnailUrl)")
                deletedFiles += 1
            } catch {
                print("❌ Erreur suppression image: \(error)")
            }
        }
        
        print("🗑️ Suppression terminée: \(deletedFiles) fichier(s) supprimé(s)")
    }
    
    /// Calculer les statistiques de stockage des images
    func getStorageStats() -> (imageCount: Int, totalSize: Int64) {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.misericode.pinpin") else {
            return (0, 0)
        }
        
        var imageCount = 0
        var totalSize: Int64 = 0
        
        // Parcourir tous les fichiers dans le dossier partagé
        if let enumerator = FileManager.default.enumerator(at: containerURL, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) {
            for case let fileURL as URL in enumerator {
                // Vérifier si c'est un fichier image
                let pathExtension = fileURL.pathExtension.lowercased()
                if ["jpg", "jpeg", "png", "gif", "webp"].contains(pathExtension) {
                    imageCount += 1
                    
                    // Obtenir la taille du fichier
                    if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                       let fileSize = resourceValues.fileSize {
                        totalSize += Int64(fileSize)
                    }
                }
            }
        }
        
        return (imageCount, totalSize)
    }
    
    /// Calculer les statistiques de stockage pour des items spécifiques
    func getStorageStatsForItems(_ items: [ContentItem]) -> (imageCount: Int, totalSize: Int64) {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.misericode.pinpin") else {
            return (0, 0)
        }
        
        var imageCount = 0
        var totalSize: Int64 = 0
        
        // Collecter uniquement les chemins des images principales
        var imagePaths: Set<String> = []
        
        for item in items {
            // Utiliser directement thumbnailUrl de l'item (nouveau système)
            if let thumbnailUrl = item.thumbnailUrl, !thumbnailUrl.isEmpty, thumbnailUrl.hasPrefix("images/") {
                imagePaths.insert(thumbnailUrl)
            }
        }
        
        // Calculer la taille de chaque image principale unique
        for imagePath in imagePaths {
            let imageURL = containerURL.appendingPathComponent(imagePath)
            
            if FileManager.default.fileExists(atPath: imageURL.path) {
                imageCount += 1
                
                // Obtenir la taille du fichier
                if let resourceValues = try? imageURL.resourceValues(forKeys: [.fileSizeKey]),
                   let fileSize = resourceValues.fileSize {
                    totalSize += Int64(fileSize)
                }
            }
        }
        
        return (imageCount, totalSize)
    }
    
    /// Formater la taille en bytes vers une chaîne lisible (KB, MB, etc.)
    func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        
        // Obtenir la chaîne formatée
        let formattedString = formatter.string(fromByteCount: bytes)
        
        // Remplacer la virgule par un point pour le séparateur décimal
        return formattedString.replacingOccurrences(of: ",", with: ".")
    }
}
