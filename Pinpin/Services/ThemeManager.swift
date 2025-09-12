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
    
    func handleTheme(forceDarkMode: Bool) {
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.overrideUserInterfaceStyle = forceDarkMode ? .dark : .unspecified
            }
        }
    }
}
