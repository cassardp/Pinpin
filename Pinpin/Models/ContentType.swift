//
//  ContentType.swift
//  Neeed2
//
//  Types de contenu supportés
//

import Foundation

enum ContentType: String, CaseIterable {
    case fashion = "fashion"
    case home = "home"
    case food = "food"
    case travel = "travel"
    case nature = "nature"
    case tech = "tech"
    case art = "art"
    case sports = "sports"
    case cars = "cars"
    case beauty = "beauty"
    case media = "media"
    case kids = "kids"
    case misc = "misc"
    
    var displayName: String {
        switch self {
        case .fashion: return "Fashion"
        case .home: return "Home"
        case .food: return "Food"
        case .travel: return "Travel"
        case .nature: return "Nature"
        case .tech: return "Tech"
        case .art: return "Art"
        case .sports: return "Sports"
        case .cars: return "Cars"
        case .beauty: return "Beauty"
        case .media: return "Media"
        case .kids: return "Kids"
        case .misc: return "Misc"
        }
    }
    
    /// Ordre des catégories avec misc forcé en dernier
    static var orderedCases: [ContentType] {
        let allCasesExceptMisc = allCases.filter { $0 != .misc }
        return allCasesExceptMisc + [.misc]
    }
}
