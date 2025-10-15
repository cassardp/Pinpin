//
//  UserPreferencesModel.swift
//  Pinpin
//
//  Modèle SwiftData pour les préférences utilisateur synchronisées via CloudKit
//

import Foundation
import SwiftData

@Model
final class UserPreferencesModel {
    var id: UUID = UUID()
    var showURLs: Bool = false
    var disableCornerRadius: Bool = false
    var showCategoryTitles: Bool = true
    var categoryOrder: Data? // Ordre des catégories sérialisé
    var isMainPreferences: Bool = false // Indique si c'est les préférences principales
    var lastUpdated: Date = Date()
    
    init(
        id: UUID = UUID(),
        showURLs: Bool = false,
        disableCornerRadius: Bool = false,
        showCategoryTitles: Bool = true,
        categoryOrder: Data? = nil,
        isMainPreferences: Bool = false,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.showURLs = showURLs
        self.disableCornerRadius = disableCornerRadius
        self.showCategoryTitles = showCategoryTitles
        self.categoryOrder = categoryOrder
        self.isMainPreferences = isMainPreferences
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Extensions pour compatibilité
extension UserPreferencesModel {
    /// Convertit les préférences en dictionnaire pour sérialisation
    var asDictionary: [String: Any] {
        return [
            "id": id.uuidString,
            "showURLs": showURLs,
            "disableCornerRadius": disableCornerRadius,
            "showCategoryTitles": showCategoryTitles,
            "isMainPreferences": isMainPreferences,
            "lastUpdated": lastUpdated
        ]
    }
    
    /// Crée une instance depuis UserDefaults
    static func fromUserDefaults() -> UserPreferencesModel {
        let prefs = UserPreferencesModel()
        prefs.showURLs = UserDefaults.standard.bool(forKey: "showURLs")
        prefs.disableCornerRadius = UserDefaults.standard.bool(forKey: "disableCornerRadius")
        prefs.showCategoryTitles = UserDefaults.standard.object(forKey: "showCategoryTitles") as? Bool ?? true
        prefs.isMainPreferences = true
        prefs.lastUpdated = Date()
        return prefs
    }
    
    /// Synchronise vers UserDefaults
    func syncToUserDefaults() {
        UserDefaults.standard.set(showURLs, forKey: "showURLs")
        UserDefaults.standard.set(disableCornerRadius, forKey: "disableCornerRadius")
        UserDefaults.standard.set(showCategoryTitles, forKey: "showCategoryTitles")
    }
}
