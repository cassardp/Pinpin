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
    
    private init() {
        self.showURLs = UserDefaults.standard.bool(forKey: "showURLs")
        self.disableCornerRadius = UserDefaults.standard.bool(forKey: "disableCornerRadius")
    }
}
