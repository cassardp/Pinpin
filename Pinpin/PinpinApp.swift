//
//  PinpinApp.swift
//  Pinpin
//
//  Created by Patrice on 12/06/2025.
//

import SwiftUI
import SwiftData

@main
struct PinpinApp: App {
    let dataService = DataService.shared
    
    init() {
        // Créer les catégories par défaut au premier lancement
        initializeDefaultCategoriesIfNeeded()
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .modelContainer(dataService.container)
                .font(.system(.body, design: .rounded))
                .onAppear {
                    // Nettoyage des URLs temporaires au démarrage
                    Task {
                        await MainActor.run {
                            dataService.cleanupInvalidImageURLs()
                        }
                    }
                }
        }
    }
    
    private func initializeDefaultCategoriesIfNeeded() {
        let hasCreatedCategories = UserDefaults.standard.bool(forKey: AppConstants.hasCreatedDefaultCategoriesKey)
        
        if !hasCreatedCategories {
            print("[PinpinApp] 🚀 Premier lancement détecté")
            Task { @MainActor in
                dataService.createDefaultCategories()
                UserDefaults.standard.set(true, forKey: AppConstants.hasCreatedDefaultCategoriesKey)
            }
        }
    }
}
