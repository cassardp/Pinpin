//
//  MaintenanceService.swift
//  Pinpin
//
//  Service pour les tâches de maintenance et nettoyage
//

import Foundation

@MainActor
final class MaintenanceService {
    static let shared = MaintenanceService()
    
    private init() {}
    
    // MARK: - Container Preparation
    
    func prepareSharedContainer() {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppConstants.groupID
        ) else {
            print("[MaintenanceService] ❌ Impossible d'accéder au container partagé")
            return
        }
        
        let libraryURL = containerURL.appendingPathComponent("Library", isDirectory: true)
        let supportURL = libraryURL.appendingPathComponent("Application Support", isDirectory: true)
        
        do {
            try FileManager.default.createDirectory(
                at: supportURL,
                withIntermediateDirectories: true
            )
            print("[MaintenanceService] ✅ Container partagé préparé")
        } catch {
            print("[MaintenanceService] ❌ Erreur lors de la préparation du container: \(error)")
        }
    }
    
    // MARK: - Metadata Encoding
    
    func encodeMetadata(_ metadata: [String: String]) -> Data? {
        guard !metadata.isEmpty else { return nil }
        
        do {
            return try JSONSerialization.data(withJSONObject: metadata)
        } catch {
            print("[MaintenanceService] ❌ Erreur lors de la sérialisation des métadonnées: \(error)")
            return nil
        }
    }
}
