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
    
    /// Détection basée sur les labels Vision avec scores de confiance (méthode améliorée)
    func detectContentTypeWithConfidence(detectedLabels: String?, confidences: String?) -> String {
        let mapper = VisionLabelMapper.shared
        
        guard let labelsString = detectedLabels, !labelsString.isEmpty,
              let confidencesString = confidences, !confidencesString.isEmpty else {
            return "misc"
        }
        
        // Parser les labels et confidences
        let labelArray = labelsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let confidenceArray = confidencesString.split(separator: ",").compactMap { Float($0.trimmingCharacters(in: .whitespaces)) }
        
        // Vérifier que les arrays ont la même taille
        guard labelArray.count == confidenceArray.count else {
            // Fallback vers la méthode sans confiance
            return mapper.mapLabelsToCategory(labelArray)
        }
        
        // Créer les objets LabelWithConfidence
        let labelsWithConfidence = zip(labelArray, confidenceArray).map { label, confidence in
            VisionLabelMapper.LabelWithConfidence(label: String(label), confidence: confidence)
        }
        
        // Utiliser la classification pondérée par confiance
        return mapper.mapLabelsWithConfidenceToCategory(labelsWithConfidence)
    }
    
    /// Détection avec fallback URL (pour compatibilité)
    func detectContentTypeWithFallback(from url: URL?, mainLabel: String?, alternatives: String?) -> String {
        // 1. Essayer d'abord la détection Vision si on a des labels
        if let main = mainLabel, !main.isEmpty {
            let visionCategory = detectContentType(mainLabel: main, alternatives: alternatives)
            
            // Construire la chaîne de labels pour le filtrage
            var allLabels = main
            if let alts = alternatives, !alts.isEmpty {
                allLabels += "," + alts
            }
            
            // Appliquer les règles de filtrage
            let finalCategory = applyContentFilters(
                category: visionCategory,
                url: url,
                detectedLabels: allLabels
            )
            
            // Si Vision donne une catégorie spécifique (pas misc), l'utiliser
            if finalCategory != "misc" {
                return finalCategory
            }
        }
        
        // 2. Fallback simple basé sur l'URL pour quelques cas spéciaux
        if let url = url {
            return detectFromURL(url)
        }
        
        return "misc"
    }
    
    /// Détection avec fallback URL utilisant les scores de confiance (méthode recommandée)
    func detectContentTypeWithConfidenceFallback(from url: URL?, detectedLabels: String?, confidences: String?) -> String {
        // 1. PRIORITÉ: Détection URL (fiable à 100% pour les domaines connus)
        if let url = url {
            let urlCategory = detectFromURL(url)
            if urlCategory != "misc" {
                return urlCategory
            }
        }
        
        // 2. Détection Vision avec confiance si on a des labels
        if let labels = detectedLabels, !labels.isEmpty {
            let visionCategory = detectContentTypeWithConfidence(detectedLabels: labels, confidences: confidences)
            
            // 3. RÈGLE SPÉCIALE: Filtrer les contenus "people" de TikTok/Instagram vers "misc"
            let finalCategory = applyContentFilters(
                category: visionCategory,
                url: url,
                detectedLabels: labels
            )
            
            // Si Vision donne une catégorie spécifique (pas misc), l'utiliser
            if finalCategory != "misc" {
                return finalCategory
            }
        }
        
        return "misc"
    }
    
    /// Détection fiable basée sur l'URL (classification à 100% de certitude)
    private func detectFromURL(_ url: URL) -> String {
        return URLDomainMapper.shared.mapURLToCategory(url)
    }
    
    // MARK: - Content Filters
    
    /// Applique des règles de filtrage spéciales pour certains contenus
    /// Exemple: contenus "people" de TikTok/Instagram → "misc"
    private func applyContentFilters(category: String, url: URL?, detectedLabels: String) -> String {
        // Règle 1: Filtrer les contenus "people" de TikTok/Instagram vers "misc"
        if shouldFilterSocialMediaPeople(category: category, url: url, detectedLabels: detectedLabels) {
            return "misc"
        }
        
        // Autres règles de filtrage peuvent être ajoutées ici
        
        return category
    }
    
    /// Vérifie si le contenu doit être filtré comme "people" de réseaux sociaux
    private func shouldFilterSocialMediaPeople(category: String, url: URL?, detectedLabels: String) -> Bool {
        // Vérifier si l'URL provient de TikTok ou Instagram
        guard let url = url else { return false }
        
        let urlString = url.absoluteString.lowercased()
        let isSocialMedia = urlString.contains("tiktok.com") || 
                           urlString.contains("instagram.com") ||
                           urlString.contains("tiktok") ||
                           urlString.contains("instagram")
        
        // Si ce n'est pas un réseau social ciblé, pas de filtrage
        guard isSocialMedia else { return false }
        
        // Vérifier si les labels contiennent "people", "person", "human", etc.
        let labels = detectedLabels.lowercased()
        let containsPeople = labels.contains("people") ||
                            labels.contains("person") ||
                            labels.contains("human") ||
                            labels.contains("crowd") ||
                            labels.contains("adult")
        
        return containsPeople
    }
}
