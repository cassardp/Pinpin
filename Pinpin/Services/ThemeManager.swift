//
//  ThemeManager.swift
//  Pinpin
//
//  Gestionnaire de thème pour forcer le mode sombre/clair
//

import Foundation
import UIKit

class ThemeManager {
    static let shared = ThemeManager()
    
    private init() {}
    
    func handleTheme(themeMode: ThemeMode) {
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                switch themeMode {
                case .system:
                    window.overrideUserInterfaceStyle = .unspecified
                case .dark:
                    window.overrideUserInterfaceStyle = .dark
                case .light:
                    window.overrideUserInterfaceStyle = .light
                }
            }
        }
    }
    
    // Méthode de compatibilité pour l'ancien système
    func handleTheme(forceDarkMode: Bool) {
        handleTheme(themeMode: forceDarkMode ? .dark : .system)
    }
}
