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
    
    init(title: String, url: String? = nil, description: String? = nil, thumbnailPath: String? = nil) {
        self.title = title
        self.url = url
        self.description = description
        self.thumbnailPath = thumbnailPath
    }
}
