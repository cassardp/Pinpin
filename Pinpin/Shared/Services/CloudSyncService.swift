//
//  CloudSyncService.swift
//  Pinpin
//
//  Service pour la gestion de la synchronisation iCloud
//

import Foundation
import CoreData
import Combine

@MainActor
final class CloudSyncService: ObservableObject {
    // MARK: - Published Properties
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var isAvailable = false
    
    private var syncCancellables = Set<AnyCancellable>()
    
    init() {
        checkAvailability()
        setupSyncMonitoring()
    }
    
    // MARK: - Availability Check
    
    func checkAvailability() {
        Task {
            do {
                // Vérifier si iCloud est disponible via FileManager
                if FileManager.default.ubiquityIdentityToken != nil {
                    await MainActor.run {
                        self.isAvailable = true
                    }
                } else {
                    await MainActor.run {
                        self.isAvailable = false
                    }
                }
            }
        }
    }
    
    // MARK: - Sync Monitoring
    
    private func setupSyncMonitoring() {
        NotificationCenter.default.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
            .sink { [weak self] notification in
                guard let self = self else { return }
                
                if let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event {
                    
                    let isFinished = event.endDate != nil
                    
                    switch (event.type, isFinished) {
                    case (.import, false), (.export, false):
                        // Début d'une synchronisation (import ou export)
                        Task { @MainActor in
                            self.isSyncing = true
                        }
                        
                    case (.import, true), (.export, true):
                        // Fin d'une synchronisation
                        Task { @MainActor in
                            self.isSyncing = false
                            self.lastSyncDate = Date()
                        }
                        
                    default:
                        break
                    }
                }
            }
            .store(in: &syncCancellables)
    }
    
    // MARK: - Status Methods
    
    func isUpToDate() -> Bool {
        return !isSyncing
    }
    
    func getStatusText() -> String {
        if !isAvailable {
            return "iCloud not available"
        } else if isSyncing {
            return "Syncing..."
        } else if let lastSync = lastSyncDate {
            let formatter = RelativeDateTimeFormatter()
            formatter.locale = Locale(identifier: "en_US")
            return "Last sync: \(formatter.localizedString(for: lastSync, relativeTo: Date()))"
        } else {
            return "Sync status unknown"
        }
    }
}
