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
    
    private init() {
        self.showURLs = UserDefaults.standard.bool(forKey: "showURLs")
    }
}
