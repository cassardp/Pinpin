import SwiftUI
import CoreData

// MARK: - PredefinedSearchView
struct PredefinedSearchView: View {
    @Binding var searchQuery: String
    var selectedContentType: String?
    let onSearchSelected: () -> Void
    
    @StateObject private var contentService = ContentServiceCoreData()
    @State private var dynamicSearches: [String] = []
    
    // Recherches préenregistrées populaires (fallback)
    private let fallbackSearches = [
        "photos", "videos", "articles", "links", "documents", 
        "recipes", "outdoor", "shopping", "books", "music",
        "work", "ideas", "inspiration", "tutorials", "news"
    ]
    
    // Recherches à afficher (dynamiques ou fallback)
    private var searchesToDisplay: [String] {
        return dynamicSearches.isEmpty ? fallbackSearches : dynamicSearches
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(searchesToDisplay, id: \.self) { searchTerm in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            searchQuery = searchTerm
                        }
                        
                        // Délai pour voir l'animation avant de fermer
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onSearchSelected()
                        }
                    }) {
                        Text(searchTerm)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(.ultraThickMaterial)
                                    .colorScheme(.dark) // Force le mode sombre pour un look cohérent
                            )
                            .scaleEffect(searchQuery == searchTerm ? 0.95 : 1.0)
                            .animation(.easeInOut(duration: 0.15), value: searchQuery)
                    }
                    .buttonStyle(PredefinedSearchButtonStyle())
                }
            }
            .padding(.leading, 16) // Alignement avec la barre de recherche
        }
        .padding(.bottom, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear {
            generateDynamicSearches()
        }
        .onChange(of: contentService.contentItems) {
            generateDynamicSearches()
        }
        .onChange(of: selectedContentType) {
            generateDynamicSearches()
        }
    }
    
    // MARK: - Dynamic Search Generation
    private func generateDynamicSearches() {
        let allItems = contentService.contentItems
        guard !allItems.isEmpty else {
            dynamicSearches = []
            return
        }
        
        // Filtrer selon la catégorie sélectionnée
        let items: [ContentItem]
        if let selectedType = selectedContentType, selectedType != "all" {
            items = allItems.filter { $0.contentType == selectedType }
        } else {
            items = allItems
        }
        
        guard !items.isEmpty else {
            dynamicSearches = []
            return
        }
        
        var labelFrequency: [String: Int] = [:]
        
        // Analyser uniquement les labels Vision des items de la catégorie
        for item in items {
            
            // Extraire les labels depuis les métadonnées
            for (key, value) in item.metadataDict {
                if key.contains("label") && !value.isEmpty {
                    // Traiter les labels (peuvent être séparés par des virgules)
                    let labels = value.components(separatedBy: ",")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    
                    for label in labels {
                        let cleanLabel = label.lowercased()
                            .replacingOccurrences(of: "_", with: " ")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        // Filtrer les labels pertinents (3-15 caractères, pas de labels techniques)
                        if cleanLabel.count >= 3 && 
                           cleanLabel.count <= 15 && 
                           !excludedLabels.contains(cleanLabel) {
                            labelFrequency[cleanLabel, default: 0] += 1
                        }
                    }
                }
            }
        }
        
        // Trier par fréquence et prendre les 15 plus populaires
        let sortedLabels = labelFrequency
            .filter { $0.value >= 1 } // Minimum 2 occurrences
            .sorted { $0.value > $1.value }
            .prefix(15)
            .map { $0.key }
        
        dynamicSearches = Array(sortedLabels)
    }
    
    
    // Labels techniques à exclure (métadonnées non pertinentes pour l'utilisateur)
    private let excludedLabels: Set<String> = [
        "vision enhanced", "wood processed", "document", "container", "adult", "structure", "material",
     ]
    
}

// MARK: - Custom Button Style
struct PredefinedSearchButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
