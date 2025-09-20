import SwiftUI
import CoreData

// MARK: - PredefinedSearchView
struct PredefinedSearchView: View {
    @Binding var searchQuery: String
    var selectedContentType: String?
    let onSearchSelected: () -> Void
    
    @StateObject private var contentService = ContentServiceCoreData()
    @State private var dynamicSearches: [String] = []
    @State private var detectedColors: [String] = []
    
    // Recherches préenregistrées populaires (fallback)
    private let fallbackSearches = [
        "photos", "videos", "articles", "links", "documents", 
        "recipes", "outdoor", "shopping", "books", "music",
        "work", "ideas", "inspiration", "tutorials", "news"
    ]
    
    // Recherches à afficher (dynamiques ou fallback + couleurs)
    private var searchesToDisplay: [String] {
        let baseSearches = dynamicSearches.isEmpty ? fallbackSearches : dynamicSearches
        return baseSearches + detectedColors
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(searchesToDisplay, id: \.self) { searchTerm in
                    Button(action: {
                        // Haptic feedback léger
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        
                        withAnimation(.easeInOut(duration: 0.2)) {
                            searchQuery = searchTerm
                        }
                        
                        // Délai pour voir l'animation avant de fermer
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onSearchSelected()
                        }
                    }) {
                        HStack(spacing: 6) {
                            // Indicateur de couleur si c'est un tag couleur
                            if detectedColors.contains(searchTerm) {
                                Circle()
                                    .fill(colorForName(searchTerm))
                                    .frame(width: 12, height: 12)
                            }
                            
                            Text(searchTerm)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(.ultraThickMaterial)
                                .colorScheme(.dark)
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
            generateColorTags()
        }
        .onChange(of: contentService.contentItems) {
            generateDynamicSearches()
            generateColorTags()
        }
        .onChange(of: selectedContentType) {
            generateDynamicSearches()
            generateColorTags()
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
    
    // MARK: - Color Tags Generation
    private func generateColorTags() {
        let allItems = contentService.contentItems
        guard !allItems.isEmpty else {
            detectedColors = []
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
            detectedColors = []
            return
        }
        
        var colorFrequency: [String: Int] = [:]
        
        // Extraire les couleurs depuis les métadonnées
        for item in items {
            for (key, value) in item.metadataDict {
                if (key.contains("color_name") || key.contains("color_name_fr")) && !value.isEmpty {
                    let colorName = value.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Utiliser les noms anglais pour l'affichage
                    let displayColor = key.contains("color_name_fr") ? 
                                     englishColorName(for: colorName) : colorName
                    
                    if supportedColors.contains(displayColor) {
                        colorFrequency[displayColor, default: 0] += 1
                    }
                }
            }
        }
        
        // Trier par fréquence et prendre les 6 couleurs les plus populaires
        let sortedColors = colorFrequency
            .filter { $0.value >= 1 } // Minimum 1 occurrence
            .sorted { $0.value > $1.value }
            .prefix(6)
            .map { $0.key }
        
        detectedColors = Array(sortedColors)
    }
    
    // MARK: - Color Utilities
    private let supportedColors: Set<String> = [
        "black", "white", "gray", "red", "orange", "yellow", 
        "green", "cyan", "blue", "purple", "magenta", "pink"
    ]
    
    private func englishColorName(for frenchName: String) -> String {
        switch frenchName {
        case "noir": return "black"
        case "blanc": return "white"
        case "gris": return "gray"
        case "rouge": return "red"
        case "orange": return "orange"
        case "jaune": return "yellow"
        case "vert": return "green"
        case "cyan": return "cyan"
        case "bleu": return "blue"
        case "violet": return "purple"
        case "magenta": return "magenta"
        case "rose": return "pink"
        default: return frenchName
        }
    }
    
    private func colorForName(_ colorName: String) -> Color {
        switch colorName {
        case "black": return .black
        case "white": return .white
        case "gray": return .gray
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "cyan": return .cyan
        case "blue": return .blue
        case "purple": return .purple
        case "magenta": return .pink
        case "pink": return .pink
        default: return .gray
        }
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
