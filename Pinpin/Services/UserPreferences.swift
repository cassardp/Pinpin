//
//  UserPreferences.swift
//  Pinpin
//
//  Service pour gérer les préférences utilisateur
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
import Observation

@Observable
class UserPreferences {
    static let shared = UserPreferences()
    
    var showURLs: Bool {
        didSet {
            UserDefaults.standard.set(showURLs, forKey: "showURLs")
        }
    }
    
    var disableCornerRadius: Bool {
        didSet {
            UserDefaults.standard.set(disableCornerRadius, forKey: "disableCornerRadius")
        }
    }

    var showCategoryTitles: Bool {
        didSet {
            UserDefaults.standard.set(showCategoryTitles, forKey: "showCategoryTitles")
        }
    }

    // Propriétés inversées pour l'interface
    var hideCategoryTitles: Bool {
        get { !showCategoryTitles }
        set { showCategoryTitles = !newValue }
    }
    
    private init() {
        self.showURLs = UserDefaults.standard.bool(forKey: "showURLs")
        self.disableCornerRadius = UserDefaults.standard.bool(forKey: "disableCornerRadius")
        // Valeurs par défaut: true pour que les toggles inversés soient false par défaut
        self.showCategoryTitles = UserDefaults.standard.object(forKey: "showCategoryTitles") as? Bool ?? true
    }
}
