//
//  ContentType.swift
//  Pinpin
//
//  Modèle simplifié pour les catégories personnalisables
//

import Foundation

// Note: Ce modèle est conservé pour la compatibilité Core Data
// mais les catégories sont maintenant gérées par CoreDataService
struct ContentCategory {
    let name: String
    
    init(_ name: String) {
        self.name = name
    }
}
