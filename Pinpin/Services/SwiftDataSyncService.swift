//
//  SwiftDataSyncService.swift
//  Pinpin
//
//  Service pour synchroniser les changements entre l'app et l'extension
//  Utilise la solution officielle Apple recommandée dans :
//  - https://developer.apple.com/forums/thread/764290
//  - https://stackoverflow.com/questions/78807833/
//
//  ⚠️ Note : Fonctionne parfaitement sur iOS 18+, partiellement sur iOS 17
//

import Foundation
import SwiftData
import Combine
import CoreData

@MainActor
final class SwiftDataSyncService: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let modelContext: ModelContext
    
    // Solution officielle Apple pour forcer le refresh
    // Changé en Date.now pour être plus précis
    @Published var lastSaveDate = Date.now
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Démarre l'écoute des changements externes (depuis l'extension)
    func startListening() {
        // Solution officielle Apple : écouter NSManagedObjectContextDidSave
        // Cette notification est émise quand l'extension sauvegarde des données
        NotificationCenter.default
            .publisher(for: .NSManagedObjectContextDidSave)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleRemoteChange(notification: notification)
            }
            .store(in: &cancellables)
        
        // Écouter aussi les changements d'objets pour une détection plus fine
        NotificationCenter.default
            .publisher(for: .NSManagedObjectContextObjectsDidChange)
            .receive(on: DispatchQueue.main)
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleObjectsChange(notification: notification)
            }
            .store(in: &cancellables)
        
        print("[SwiftDataSync] 🎧 Écoute des changements externes démarrée")
    }
    
    /// Arrête l'écoute
    func stopListening() {
        cancellables.removeAll()
        print("[SwiftDataSync] 🛑 Écoute arrêtée")
    }
    
    /// Traite les changements détectés lors d'une sauvegarde
    private func handleRemoteChange(notification: Notification) {
        // Vérifier si le changement vient d'un autre contexte (extension)
        // On ne peut pas comparer directement les contextes, donc on rafraîchit toujours
        // Le rollback() est peu coûteux et garantit la synchronisation
        
        print("[SwiftDataSync] 🔔 Changement externe détecté (sauvegarde)")
        refreshContext()
    }
    
    /// Traite les changements d'objets
    private func handleObjectsChange(notification: Notification) {
        // Vérifier s'il y a des objets insérés, mis à jour ou supprimés
        let userInfo = notification.userInfo
        let hasInserted = (userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject>)?.isEmpty == false
        let hasUpdated = (userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>)?.isEmpty == false
        let hasDeleted = (userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject>)?.isEmpty == false
        
        if hasInserted || hasUpdated || hasDeleted {
            print("[SwiftDataSync] 🔔 Objets modifiés détectés")
            refreshContext()
        }
    }
    
    /// Rafraîchit le contexte et force le refresh des vues
    private func refreshContext() {
        // Vider le cache pour forcer la lecture depuis le disque
        modelContext.rollback()
        
        // Forcer le refresh des vues avec .id()
        // Utiliser .now pour garantir un changement de valeur
        lastSaveDate = Date.now
        
        print("[SwiftDataSync] ✅ Contexte rafraîchi à \(lastSaveDate)")
    }
    
    /// Force un refresh manuel (utile pour le retour en foreground)
    func forceRefresh() {
        print("[SwiftDataSync] 🔄 Refresh manuel forcé")
        refreshContext()
    }
}
