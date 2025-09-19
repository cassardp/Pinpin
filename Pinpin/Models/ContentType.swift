//
//  ContentType.swift
//  Neeed2
//
//  Types de contenu supportés
//

import Foundation

enum ContentType: String, CaseIterable {
    case home = "home"
    case fashion = "fashion"
    case food = "food"
    case tech = "tech"
    case beauty = "beauty"
    case books = "books"
    case music = "music"
    case show = "show"
    case sports = "sports"
    case outdoor = "outdoor"
    case animals = "animals"
    case cars = "cars"
    case art = "art"
    case misc = "misc"
    
    var displayName: String {
        switch self {
        case .home: return "Home"
        case .fashion: return "Fashion"
        case .food: return "Food"
        case .tech: return "Tech"
        case .beauty: return "Beauty"
        case .books: return "Books"
        case .music: return "Music"
        case .show: return "Show"
        case .sports: return "Sports"
        case .outdoor: return "Outdoor"
        case .animals: return "Animals"
        case .cars: return "Cars"
        case .art: return "Art"
        case .misc: return "Misc"
        }
    }
    
    /// Ordre des catégories avec misc forcé en dernier
    static var orderedCases: [ContentType] {
        let allCasesExceptMisc = allCases.filter { $0 != .misc }
        return allCasesExceptMisc + [.misc]
    }
}
