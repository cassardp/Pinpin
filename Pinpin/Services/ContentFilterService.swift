//
//  ContentFilterService.swift
//  Pinpin
//
//  Service centralisé pour le filtrage et la recherche de contenu
//

import Foundation

final class ContentFilterService {
    static let shared = ContentFilterService()
    
    private init() {}
    
    /// Filtre les items selon une catégorie et une requête de recherche
    /// - Parameters:
    ///   - items: Les items à filtrer
    ///   - category: La catégorie sélectionnée (nil = toutes)
    ///   - query: La requête de recherche
    /// - Returns: Les items filtrés
    func filter(
        items: [ContentItem],
        category: String?,
        query: String
    ) -> [ContentItem] {
        // Filtrage par catégorie
        let categoryFiltered = filterByCategory(items: items, category: category)
        
        // Filtrage par recherche
        let searchQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !searchQuery.isEmpty else { return categoryFiltered }
        
        return filterByQuery(items: categoryFiltered, query: searchQuery)
    }
    
    /// Filtre les items par catégorie
    private func filterByCategory(items: [ContentItem], category: String?) -> [ContentItem] {
        guard let category = category else { return items }
        return items.filter { $0.category?.name == category }
    }
    
    /// Filtre les items par requête de recherche
    private func filterByQuery(items: [ContentItem], query: String) -> [ContentItem] {
        return items.filter { item in
            matchesQuery(item: item, query: query)
        }
    }
    
    /// Vérifie si un item correspond à la requête
    private func matchesQuery(item: ContentItem, query: String) -> Bool {
        let title = item.title.lowercased()
        let description = (item.metadataDict["best_description"] ?? item.itemDescription ?? "").lowercased()
        let url = item.url?.lowercased() ?? ""
        let metadataValues = item.metadataDict.values
            .joined(separator: " ")
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
        
        // Gestion spéciale pour Twitter/X
        if query == "twitter" {
            return containsTwitter(title: title, description: description, url: url, metadata: metadataValues)
        }
        
        return title.contains(query)
            || description.contains(query)
            || url.contains(query)
            || metadataValues.contains(query)
    }
    
    /// Vérifie si le contenu est lié à Twitter/X
    private func containsTwitter(title: String, description: String, url: String, metadata: String) -> Bool {
        let twitterTerms = ["twitter", "x.com"]
        
        for term in twitterTerms {
            if title.contains(term) || description.contains(term) || url.contains(term) || metadata.contains(term) {
                return true
            }
        }
        
        return false
    }
    
    /// Compte les items par catégorie
    func countByCategory(items: [ContentItem], category: String?) -> Int {
        guard let category = category else { return items.count }
        return items.filter { $0.category?.name == category }.count
    }
}
