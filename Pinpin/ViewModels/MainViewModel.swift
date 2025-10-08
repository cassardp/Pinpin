//
//  MainViewModel.swift
//  Pinpin
//
//  ViewModel pour MainView - Gère la logique de filtrage, recherche et sélection
//

import SwiftUI
import Combine

@MainActor
final class MainViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var searchQuery: String = ""
    @Published var selectedContentType: String?
    @Published var isSelectionMode: Bool = false
    @Published var selectedItems: Set<UUID> = []
    @Published var showSearchBar: Bool = false
    @Published var scrollProgress: CGFloat = 0
    @Published var displayLimit: Int = AppConstants.itemsPerPage
    
    // MARK: - Dependencies
    private let dataService = DataService.shared
    
    // MARK: - Filtering Logic
    
    /// Filtre les items selon la catégorie et la recherche avec pagination
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
        let searchFiltered: [ContentItem]
        if query.isEmpty {
            searchFiltered = typeFiltered
        } else {
            searchFiltered = typeFiltered.filter { item in
                matchesSearchQuery(item: item, query: query)
            }
        }
        
        // Déduplication par id pour éviter les doublons visuels
        let unique = uniquedById(searchFiltered)
        
        // Pagination côté UI
        return Array(unique.prefix(displayLimit))
    }
    
    /// Compte total des items (avant pagination) pour savoir s'il y en a plus
    func totalItemsCount(from allItems: [ContentItem]) -> Int {
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
            return uniquedById(typeFiltered).count
        }
        
        let filtered = typeFiltered.filter { item in
            matchesSearchQuery(item: item, query: query)
        }
        return uniquedById(filtered).count
    }
    
    /// Charge plus d'items (augmente la limite)
    func loadMoreIfNeeded(currentIndex: Int, totalItems: Int, totalBeforePagination: Int) {
        // Charger plus si on arrive vers la fin (5 items avant)
        if currentIndex >= totalItems - 5 && displayLimit < totalBeforePagination {
            let oldLimit = displayLimit
            displayLimit += AppConstants.itemsPerPage
            print("📄 Pagination: Loading more items - from \(oldLimit) to \(displayLimit) (currentIndex: \(currentIndex)/\(totalItems), total: \(totalBeforePagination))")
        }
    }
    
    /// Reset la pagination (au changement de catégorie ou recherche)
    func resetPagination() {
        displayLimit = AppConstants.itemsPerPage
        print("🔄 Pagination: Reset to \(displayLimit) items")
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
    
    func deleteSelectedItems(from items: [ContentItem]) {
        let itemsToDelete = items.filter { selectedItems.contains($0.safeId) }
        for item in itemsToDelete {
            dataService.deleteContentItem(item)
        }
        selectedItems.removeAll()
        isSelectionMode = false
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
        resetPagination()
    }
    
    // MARK: - Category Management
    
    func selectCategory(_ category: String?) {
        selectedContentType = category
        resetPagination()
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

    // MARK: - Dedup Helper
    private func uniquedById(_ items: [ContentItem]) -> [ContentItem] {
        var seen = Set<UUID>()
        return items.filter { seen.insert($0.id).inserted }
    }
}
