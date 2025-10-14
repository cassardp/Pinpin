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
    
    // MARK: - Filtering Logic
    
    /// Filtre les items selon la catégorie et la recherche
    func filteredItems(from allItems: [ContentItem]) -> [ContentItem] {
        // Filtrage par catégorie
        let typeFiltered: [ContentItem]
        if let selectedType = selectedContentType {
            typeFiltered = allItems.filter { $0.safeCategoryName == selectedType }
        } else {
            typeFiltered = allItems
        }
        
        // Filtrage par recherche
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            return typeFiltered
        }
        
        return typeFiltered.filter { item in
            matchesSearchQuery(item: item, query: query)
        }
    }
    
    /// Vérifie si un item correspond à la requête de recherche
    private func matchesSearchQuery(item: ContentItem, query: String) -> Bool {
        let title = item.title.lowercased()
        let description = (item.metadataDict["best_description"] ?? item.itemDescription ?? "").lowercased()
        let url = item.url?.lowercased() ?? ""
        let metadataValues = item.metadataDict.values
            .joined(separator: " ")
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
        
        // Gestion spéciale pour Twitter/X
        if query == "twitter" {
            return title.contains("twitter") || title.contains("x.com")
                || description.contains("twitter") || description.contains("x.com")
                || url.contains("x.com")
                || metadataValues.contains("twitter") || metadataValues.contains("x.com")
        }
        
        return title.contains(query)
            || description.contains(query)
            || url.contains(query)
            || metadataValues.contains(query)
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
