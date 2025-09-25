//
//  SharedContentData.swift
//  PinpinShareExtension
//
//  Structure de données pour le contenu partagé simplifié
//

import Foundation

struct SharedContentData {
    let title: String
    let url: String?
    let description: String?
    let thumbnailPath: String?
    let imageData: Data? // Nouvelle propriété pour les données d'image
    
    init(title: String, url: String? = nil, description: String? = nil, thumbnailPath: String? = nil, imageData: Data? = nil) {
        self.title = title
        self.url = url
        self.description = description
        self.thumbnailPath = thumbnailPath
        self.imageData = imageData
    }
}
