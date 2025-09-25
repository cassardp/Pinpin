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
}
