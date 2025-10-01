//
//  SwiftDataSyncService.swift
//  Pinpin
//
//  Service pour synchroniser les changements entre l'app et l'extension
//  Utilise Persistent History Tracking (solution officielle Apple)
//

import Foundation
import SwiftData
import Combine
import CoreData

@MainActor
final class SwiftDataSyncService: ObservableObject {
    private var cancellable: AnyCancellable?
    private let modelContext: ModelContext
    
    // Solution officielle Apple pour forcer le refresh
    @Published var lastSaveDate = Date()
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Démarre l'écoute des changements externes (depuis l'extension)
    func startListening() {
        // Solution officielle Apple : écouter NSManagedObjectContextDidSave
        cancellable = NotificationCenter.default
            .publisher(for: .NSManagedObjectContextDidSave)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleRemoteChange()
            }
        
        print("[SwiftDataSync] 🎧 Écoute des changements externes démarrée")
    }
    
    /// Arrête l'écoute
    func stopListening() {
        cancellable?.cancel()
        cancellable = nil
        print("[SwiftDataSync] 🛑 Écoute arrêtée")
    }
    
    /// Traite les changements détectés
    private func handleRemoteChange() {
        print("[SwiftDataSync] 🔔 Changement détecté")
        
        // Vider le cache pour forcer la lecture depuis le disque
        modelContext.rollback()
        
        // Forcer le refresh des vues avec .id()
        lastSaveDate = Date()
    }
}
