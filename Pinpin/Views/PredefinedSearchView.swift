import SwiftUI
import CoreData

// MARK: - PredefinedSearchView
struct PredefinedSearchView: View {
    @Binding var searchQuery: String
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
                                    .fill(.thinMaterial)
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
    }
    
    // MARK: - Dynamic Search Generation
    private func generateDynamicSearches() {
        let items = contentService.contentItems
        guard !items.isEmpty else {
            dynamicSearches = []
            return
        }
        
        var keywordFrequency: [String: Int] = [:]
        var imageUrlKeywords: Set<String> = [] // Mots-clés qui viennent des URLs d'images
        
        // Analyser les contenus pour extraire des mots-clés pertinents
        for item in items {
            
            // Analyser les titres
            if let title = item.title {
                let titleKeywords = extractKeywords(from: title)
                titleKeywords.forEach { keyword in
                    keywordFrequency[keyword, default: 0] += 2 // Poids plus élevé pour les titres
                }
            }
            
            // Analyser les descriptions
            let description = item.metadataDict["best_description"] ?? item.itemDescription ?? ""
            if !description.isEmpty {
                let descKeywords = extractKeywords(from: description)
                descKeywords.forEach { keyword in
                    keywordFrequency[keyword, default: 0] += 1
                }
            }
            
            // Analyser les métadonnées (labels Vision, etc.)
            for (key, value) in item.metadataDict {
                if key.contains("label") || key.contains("tag") {
                    let metaKeywords = extractKeywords(from: value)
                    metaKeywords.forEach { keyword in
                        keywordFrequency[keyword, default: 0] += 1
                    }
                }
            }
            
            // Analyser les URLs pour les domaines populaires
            if let url = item.url {
                let urlKeywords = extractDomainKeywords(from: url)
                urlKeywords.forEach { keyword in
                    keywordFrequency[keyword, default: 0] += 3 // Poids élevé pour les domaines
                }
            }
            
            // Collecter les mots-clés des URLs d'images pour les exclure
            for (key, value) in item.metadataDict {
                if key.contains("url") && (key.contains("image") || key.contains("thumbnail") || key.contains("icon")) {
                    let imgUrlKeywords = extractKeywords(from: value)
                    imgUrlKeywords.forEach { keyword in
                        imageUrlKeywords.insert(keyword)
                    }
                }
            }
        }
        
        // Trier par fréquence et prendre les 15 plus populaires
        // Exclure les mots-clés qui proviennent des URLs d'images
        let sortedKeywords = keywordFrequency
            .filter { $0.value >= 2 } // Minimum 2 occurrences
            .filter { !imageUrlKeywords.contains($0.key) } // Exclure les mots-clés des URLs d'images
            .sorted { $0.value > $1.value }
            .prefix(15)
            .map { $0.key }
        
        dynamicSearches = Array(sortedKeywords)
    }
    
    // MARK: - Keyword Extraction
    private func extractKeywords(from text: String) -> [String] {
        let cleanText = text.lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s]", with: " ", options: .regularExpression)
        
        let words = cleanText.components(separatedBy: .whitespacesAndNewlines)
            .filter { word in
                word.count >= 3 && // Minimum 3 caractères
                word.count <= 15 && // Maximum 15 caractères
                !stopWords.contains(word) // Exclure les mots vides
            }
        
        return Array(Set(words)) // Supprimer les doublons
    }
    
    private func extractDomainKeywords(from url: String) -> [String] {
        guard let urlObj = URL(string: url),
              let host = urlObj.host else { return [] }
        
        let domain = host.replacingOccurrences(of: "www.", with: "")
        
        // Mapper les domaines populaires vers des mots-clés pertinents
        let domainKeywords: [String: [String]] = [
            "youtube.com": ["videos", "youtube"],
            "instagram.com": ["photos", "instagram"],
            "twitter.com": ["tweets", "social"],
            "x.com": ["tweets", "social"],
            "github.com": ["code", "development"],
            "medium.com": ["articles", "blog"],
            "reddit.com": ["discussions", "reddit"],
            "pinterest.com": ["inspiration", "photos"],
            "linkedin.com": ["professional", "work"],
            "tiktok.com": ["videos", "tiktok"],
            "amazon.com": ["shopping", "products"],
            "spotify.com": ["music", "audio"],
            "apple.com": ["tech", "apple"],
            "netflix.com": ["movies", "entertainment"]
        ]
        
        return domainKeywords[domain] ?? [domain.components(separatedBy: ".").first ?? domain]
    }
    
    // Mots vides à exclure
    private let stopWords: Set<String> = [
        "the", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by",
        "from", "up", "about", "into", "through", "during", "before", "after", "above",
        "below", "between", "among", "under", "over", "this", "that", "these", "those",
        "is", "are", "was", "were", "be", "been", "being", "have", "has", "had", "do",
        "does", "did", "will", "would", "could", "should", "may", "might", "must",
        "can", "shall", "get", "got", "make", "made", "take", "took", "come", "came",
        "go", "went", "see", "saw", "know", "knew", "think", "thought", "say", "said",
        "tell", "told", "become", "became", "leave", "left", "find", "found", "give",
        "gave", "use", "used", "work", "worked", "call", "called", "try", "tried",
        "ask", "asked", "need", "needed", "feel", "felt", "seem", "seemed", "turn",
        "turned", "start", "started", "show", "showed", "hear", "heard", "play",
        "played", "run", "ran", "move", "moved", "live", "lived", "believe", "believed",
        "hold", "held", "bring", "brought", "happen", "happened", "write", "wrote",
        "provide", "provided", "sit", "sat", "stand", "stood", "lose", "lost", "pay",
        "paid", "meet", "met", "include", "included", "continue", "continued", "set",
        "learn", "learned", "change", "changed", "lead", "led", "understand", "understood",
        "watch", "watched", "follow", "followed", "stop", "stopped", "create", "created",
        "speak", "spoke", "read", "allow", "allowed", "add", "added", "spend", "spent",
        "grow", "grew", "open", "opened", "walk", "walked", "win", "won", "offer",
        "offered", "remember", "remembered", "love", "loved", "consider", "considered",
        "appear", "appeared", "buy", "bought", "wait", "waited", "serve", "served",
        "die", "died", "send", "sent", "expect", "expected", "build", "built", "stay",
        "stayed", "fall", "fell", "cut", "reach", "reached", "kill", "killed", "remain",
        "remained", "suggest", "suggested", "raise", "raised", "pass", "passed", "sell",
        "sold", "require", "required", "report", "reported", "decide", "decided", "pull",
        "pulled", "structure", "nich", "sur", "pin", "vision", "enhanced", "processed", "material", "img"
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
