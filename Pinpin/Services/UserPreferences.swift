//
//  UserPreferences.swift
//  Neeed2
//
//  Service pour gérer les préférences utilisateur
//

import Foundation

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
    
    @Published var forceDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(forceDarkMode, forKey: "forceDarkMode")
            ThemeManager.shared.handleTheme(forceDarkMode: forceDarkMode)
        }
    }
    
    @Published var devMode: Bool {
        didSet {
            UserDefaults.standard.set(devMode, forKey: "devMode")
        }
    }
    
    private init() {
        self.showURLs = UserDefaults.standard.bool(forKey: "showURLs")
        self.disableCornerRadius = UserDefaults.standard.bool(forKey: "disableCornerRadius")
        self.forceDarkMode = UserDefaults.standard.bool(forKey: "forceDarkMode")
        self.devMode = UserDefaults.standard.bool(forKey: "devMode")
        
        // Appliquer le thème au démarrage
        ThemeManager.shared.handleTheme(forceDarkMode: self.forceDarkMode)
    }
}
