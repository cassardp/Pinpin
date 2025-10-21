//
//  MainViewModel.swift
//  Pinpin
//
//  ViewModel pour MainView - Gère la logique de filtrage, recherche et sélection
//

import SwiftUI

@MainActor
@Observable
final class MainViewModel {
    // MARK: - State Properties
    var searchQuery: String = ""
    var selectedContentType: String?
    var isSelectionMode: Bool = false
    var selectedItems: Set<UUID> = []
    var showSearchBar: Bool = false
    var scrollProgress: CGFloat = 0

    // MARK: - Cache Properties
    private var cachedFilteredItems: [ContentItem] = []
    private var lastAllItemsIDs: [UUID] = []
    private var lastSearchQuery: String = ""
    private var lastSelectedType: String?

    // MARK: - Filtering Logic

    /// Filtre les items selon la catégorie et la recherche (avec cache)
    func filteredItems(from allItems: [ContentItem]) -> [ContentItem] {
        let currentItemIDs = allItems.map { $0.safeId }
        let currentQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // Vérifier si le cache est toujours valide
        let cacheValid = currentItemIDs == lastAllItemsIDs
            && currentQuery == lastSearchQuery
            && selectedContentType == lastSelectedType

        if cacheValid {
            return cachedFilteredItems
        }

        // Recalculer et mettre en cache
        let typeFiltered: [ContentItem]
        if let selectedType = selectedContentType {
            typeFiltered = allItems.filter { $0.safeCategoryName == selectedType }
        } else {
            typeFiltered = allItems
        }

        let result: [ContentItem]
        if currentQuery.isEmpty {
            result = typeFiltered
        } else {
            result = typeFiltered.filter { item in
                matchesSearchQuery(item: item, query: currentQuery)
            }
        }

        // Mettre à jour le cache
        cachedFilteredItems = result
        lastAllItemsIDs = currentItemIDs
        lastSearchQuery = currentQuery
        lastSelectedType = selectedContentType

        return result
    }
    
    /// Vérifie si un item correspond à la requête de recherche (optimisé)
    private func matchesSearchQuery(item: ContentItem, query: String) -> Bool {
        let title = item.title.lowercased()
        let url = item.url?.lowercased() ?? ""

        // Gestion spéciale pour Twitter/X avec early return
        if query == "twitter" {
            return title.contains("twitter") || title.contains("x.com")
                || url.contains("x.com")
        }

        // Vérifier d'abord les champs simples (plus rapide)
        if title.contains(query) || url.contains(query) {
            return true
        }

        // Parser metadata uniquement si nécessaire (plus coûteux)
        let metadata = item.metadataDict
        let description = (metadata["best_description"] ?? item.itemDescription ?? "").lowercased()

        if description.contains(query) {
            return true
        }

        // Chercher dans les métadonnées uniquement en dernier recours
        let metadataValues = metadata.values
            .joined(separator: " ")
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")

        return metadataValues.contains(query)
    }
    
    // MARK: - Selection Management
    
    func toggleItemSelection(_ itemId: UUID) {
        if selectedItems.contains(itemId) {
            selectedItems.remove(itemId)
        } else {
            selectedItems.insert(itemId)
        }
    }
    
    func selectAll(from items: [ContentItem]) {
        selectedItems = Set(items.map { $0.safeId })
    }
    
    func cancelSelection() {
        selectedItems.removeAll()
        isSelectionMode = false
    }
    
    // MARK: - Search Management
    
    func openSearch() {
        // Restaurer la barre à sa taille normale
        scrollProgress = 0.0
        showSearchBar = true
    }
    
    func closeSearch() {
        showSearchBar = false
    }
    
    func clearSearch() {
        searchQuery = ""
    }
    
    // MARK: - Category Management
    
    func selectCategory(_ category: String?) {
        selectedContentType = category
    }
    
    func clearCategory() {
        selectedContentType = nil
    }
    
    // MARK: - Share
    
    func shareCurrentCategory(items: [ContentItem]) -> String {
        let categoryName = selectedContentType?.capitalized ?? "All"
        var shareText = "My \(categoryName) pins:\n\n"
        
        for item in items {
            let title = item.title.isEmpty ? "Untitled" : item.title
            let url = (item.url?.isEmpty ?? true) ? "No URL" : (item.url ?? "No URL")
            shareText += "• \(title)\n  \(url)\n\n"
        }
        
        shareText += "Shared from Pinpin"
        return shareText
    }
}
