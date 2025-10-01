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
    private var isProcessing = false
    private var lastProcessedDate = Date.distantPast
    
    @Published var hasNewChanges = false
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Démarre l'écoute des changements externes (depuis l'extension)
    func startListening() {
        // Écouter les changements du store persistant avec debounce
        cancellable = NotificationCenter.default
            .publisher(for: .NSPersistentStoreRemoteChange)
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main) // Grouper les notifications
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.handleRemoteChange()
                }
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
        // Éviter le traitement multiple
        guard !isProcessing else {
            print("[SwiftDataSync] ⏭️ Traitement déjà en cours, ignoré")
            return
        }
        
        // Éviter de traiter trop souvent (minimum 2 secondes entre chaque traitement)
        let timeSinceLastProcess = Date().timeIntervalSince(lastProcessedDate)
        guard timeSinceLastProcess > 2.0 else {
            print("[SwiftDataSync] ⏭️ Trop récent (\(String(format: "%.1f", timeSinceLastProcess))s), ignoré")
            return
        }
        
        isProcessing = true
        lastProcessedDate = Date()
        
        print("[SwiftDataSync] 🔔 Changement externe détecté - traitement...")
        
        // Forcer le contexte à vider son cache et relire depuis le disque
        modelContext.rollback()
        
        // Notifier qu'il y a de nouveaux changements
        hasNewChanges = true
        
        // Réinitialiser après un court délai
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
            await MainActor.run {
                self.hasNewChanges = false
                self.isProcessing = false
            }
        }
    }
}
