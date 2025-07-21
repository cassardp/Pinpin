//
//  ContentType.swift
//  Neeed2
//
//  Types de contenu supportés
//

import Foundation

enum ContentType: String, CaseIterable {
    case webpage = "webpage"
    case article = "article"
    case video = "video"
    case music = "music"
    case image = "image"
    case social = "social"
    case app = "app"
    case product = "product"
    case book = "book"
    case podcast = "podcast"
    case show = "show"
    case text = "text"
    
    var displayName: String {
        switch self {
        case .webpage: return "Web"
        case .article: return "Article"
        case .video: return "Video"
        case .music: return "Music"
        case .image: return "Photo"
        case .social: return "Social"
        case .app: return "App"
        case .product: return "Shopping"
        case .book: return "Book"
        case .podcast: return "Podcast"
        case .show: return "Show"
        case .text: return "Text"
        }
    }
}
