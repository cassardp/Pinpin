//
//  UserPreferences.swift
//  Neeed2
//
//  Service pour gérer les préférences utilisateur
//

import Foundation
import UIKit

enum ThemeMode: String, CaseIterable {
    case system = "system"
    case dark = "dark"
    case light = "light"
}

class UserPreferences: ObservableObject {
    static let shared = UserPreferences()
    
    @Published var showURLs: Bool {
        didSet {
            UserDefaults.standard.set(showURLs, forKey: "showURLs")
        }
    }
    
    @Published var disableCornerRadius: Bool {
        didSet {
            UserDefaults.standard.set(disableCornerRadius, forKey: "disableCornerRadius")
        }
    }
    
    @Published var themeMode: ThemeMode {
        didSet {
            UserDefaults.standard.set(themeMode.rawValue, forKey: "themeMode")
            ThemeManager.shared.handleTheme(themeMode: themeMode)
        }
    }
    
    // Propriété computed pour compatibilité avec l'interface
    var forceDarkMode: Bool {
        get { themeMode != .system }
        set { 
            if newValue {
                // Si on active, on détermine le mode à forcer selon le mode système actuel
                themeMode = getCurrentSystemScheme() == .dark ? .light : .dark
            } else {
                themeMode = .system
            }
        }
    }
    
    @Published var devMode: Bool {
        didSet {
            UserDefaults.standard.set(devMode, forKey: "devMode")
        }
    }
    
    @Published var hideMiscCategory: Bool {
        didSet {
            UserDefaults.standard.set(hideMiscCategory, forKey: "hideMiscCategory")
        }
    }
    
    private init() {
        self.showURLs = UserDefaults.standard.bool(forKey: "showURLs")
        self.disableCornerRadius = UserDefaults.standard.bool(forKey: "disableCornerRadius")
        self.devMode = UserDefaults.standard.bool(forKey: "devMode")
        self.hideMiscCategory = UserDefaults.standard.bool(forKey: "hideMiscCategory")
        
        // Migration de l'ancien système
        if let savedTheme = UserDefaults.standard.string(forKey: "themeMode"),
           let themeMode = ThemeMode(rawValue: savedTheme) {
            self.themeMode = themeMode
        } else {
            // Migration depuis l'ancien forceDarkMode
            let oldForceDarkMode = UserDefaults.standard.bool(forKey: "forceDarkMode")
            self.themeMode = oldForceDarkMode ? .dark : .system
        }
        
        // Appliquer le thème au démarrage
        ThemeManager.shared.handleTheme(themeMode: self.themeMode)
    }
    
    private func getCurrentSystemScheme() -> UIUserInterfaceStyle {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.traitCollection.userInterfaceStyle
        }
        return .unspecified
    }
}
