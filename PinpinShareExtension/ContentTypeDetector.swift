//
//  ContentTypeDetector.swift
//  PinpinShareExtension
//
//  Service pour détecter automatiquement le type de contenu basé sur Vision
//

import Foundation

class ContentTypeDetector {
    
    static let shared = ContentTypeDetector()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Détection basée sur les labels Vision (méthode principale)
    func detectContentType(mainLabel: String?, alternatives: String?) -> String {
        let mapper = VisionLabelMapper.shared
        
        // Construire la liste des labels à analyser
        var labels: [String] = []
        
        if let main = mainLabel, !main.isEmpty {
            labels.append(main)
        }
        
        if let alts = alternatives, !alts.isEmpty {
            let altLabels = alts.split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .prefix(4) // Limite aux 4 premiers alternatives pour éviter le bruit
            labels.append(contentsOf: altLabels)
        }
        
        // Si on a des labels, utiliser le mapper
        if !labels.isEmpty {
            return mapper.mapLabelsToCategory(labels)
        }
        
        return "misc"
    }
    
    /// Détection avec fallback URL (pour compatibilité)
    func detectContentTypeWithFallback(from url: URL?, mainLabel: String?, alternatives: String?) -> String {
        // 1. Essayer d'abord la détection Vision si on a des labels
        if let main = mainLabel, !main.isEmpty {
            let visionCategory = detectContentType(mainLabel: main, alternatives: alternatives)
            
            // Si Vision donne une catégorie spécifique (pas misc), l'utiliser
            if visionCategory != "misc" {
                return visionCategory
            }
        }
        
        // 2. Fallback simple basé sur l'URL pour quelques cas spéciaux
        if let url = url {
            return detectFromURL(url)
        }
        
        return "misc"
    }
    
    /// Détection simple basée sur l'URL (fallback minimal)
    private func detectFromURL(_ url: URL) -> String {
        let urlString = url.absoluteString.lowercased()
        
        // Quelques détections simples pour les cas évidents
        if urlString.contains("youtube.com") || urlString.contains("youtu.be") ||
           urlString.contains("netflix.com") || urlString.contains("spotify.com") {
            return "media"
        }
        
        if urlString.contains("airbnb.com") || urlString.contains("booking.com") {
            return "travel"
        }
        
        if urlString.contains("apps.apple.com") || urlString.contains("play.google.com") {
            return "tech"
        }
        
        return "misc"
    }
}
