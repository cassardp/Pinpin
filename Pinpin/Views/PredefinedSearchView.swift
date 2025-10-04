import SwiftData
import SwiftUI

// MARK: - PredefinedSearchView
struct PredefinedSearchView: View {
    @Binding var searchQuery: String
    var selectedContentType: String?
    let onSearchSelected: () -> Void

    @Query(sort: \ContentItem.createdAt, order: .reverse)
    private var allContentItems: [ContentItem]

    @State private var domains: [String] = []
    @State private var hapticTrigger: Int = 0

    // Recherches à afficher (domaines uniquement)
    private var searchesToDisplay: [String] {
        return domains.map { getDisplayName(for: $0) }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(searchesToDisplay.enumerated()), id: \.element) { index, displayTerm in
                    Button(action: {
                        hapticTrigger += 1

                        withAnimation(.easeInOut(duration: 0.2)) {
                            // Utiliser le terme de recherche approprié
                            searchQuery = getSearchTermForDomain(domains[index])
                        }

                        // Délai pour voir l'animation avant de fermer
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onSearchSelected()
                        }
                    }) {
                        Text(displayTerm)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(.ultraThickMaterial)
                                    .colorScheme(.dark)
                            )
                    }
                    .buttonStyle(PredefinedSearchButtonStyle())
                }
            }
            .padding(.leading, 16)  // Alignement avec la barre de recherche
        }
        .padding(.bottom, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
        .onAppear {
            generateDynamicSearches()
        }
        .onChange(of: allContentItems.count) {
            generateDynamicSearches()
        }
        .onChange(of: selectedContentType) {
            generateDynamicSearches()
        }
    }

    // MARK: - Dynamic Search Generation
    private func generateDynamicSearches() {
        let allItems = allContentItems
        guard !allItems.isEmpty else {
            domains = []
            return
        }

        // Filtrer selon la catégorie sélectionnée
        let items: [ContentItem]
        if let selectedType = selectedContentType, selectedType != "all" {
            items = allItems.filter { $0.safeCategoryName == selectedType }
        } else {
            items = allItems
        }

        guard !items.isEmpty else {
            domains = []
            return
        }

        // Extraire les domaines
        extractDomains(from: items)

        var keywordFrequency: [String: Int] = [:]

        // Extraire des mots-clés depuis les URLs et le texte OCR
        for item in items {
            var itemKeywords: Set<String> = []

            // Analyser l'URL (domaine et path)
            if let urlString = item.url, let url = URL(string: urlString) {
                // Traitement spécial pour les domaines connus
                let processedHost = processSpecialDomains(url.host ?? "")
                let urlKeywords = extractKeywords(from: processedHost)
                itemKeywords.formUnion(urlKeywords)

                // Extraire aussi des mots du path
                let pathKeywords = extractKeywords(from: url.pathComponents.joined(separator: " "))
                itemKeywords.formUnion(pathKeywords)
            }

            // Analyser le texte OCR si disponible
            if let ocrText = item.metadataDict["ocr_text"], !ocrText.isEmpty {
                let ocrKeywords = extractKeywords(from: ocrText)
                itemKeywords.formUnion(ocrKeywords)
            }

            // Compter chaque mot-clé unique une seule fois par item
            for keyword in itemKeywords {
                keywordFrequency[keyword, default: 0] += 1
            }
        }

        // Code de génération des mots-clés supprimé car on utilise maintenant uniquement les domaines
        _ = keywordFrequency

    }

    // MARK: - Keyword Extraction
    private func extractKeywords(from text: String) -> Set<String> {
        var keywords: Set<String> = []

        // Nettoyer et normaliser le texte
        let cleanText =
            text
            .lowercased()
            .replacingOccurrences(
                of: "[^a-zA-Z0-9àâäéèêëïîôöùûüÿç\\s-]", with: " ", options: .regularExpression
            )
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Diviser en mots
        let words = cleanText.components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }

        for word in words {
            // Filtrer les mots pertinents
            if word.count >= 3 && word.count <= 20 && !stopWords.contains(word)
                && !excludedTerms.contains(word) && !isNumericSequence(word)
            {
                keywords.insert(word)
            }
        }

        return keywords
    }

    // MARK: - Special Domains Processing
    private func processSpecialDomains(_ host: String) -> String {
        // Mapper les domaines courts vers leurs vraies plateformes
        switch host.lowercased() {
        case "pin.it":
            return "pinterest"
        case "t.co":
            return "x"
        case "bit.ly", "tinyurl.com", "short.link":
            return "shortlink"
        case "youtu.be":
            return "youtube"
        case "amzn.to":
            return "amazon"
        default:
            return host
        }
    }

    // MARK: - Domain Extraction
    private func extractDomains(from items: [ContentItem]) {
        var domainFrequency: [String: Int] = [:]

        for item in items {
            guard let urlString = item.url, let url = URL(string: urlString) else { continue }

            if let host = url.host {
                // Nettoyer le domaine (enlever www, etc.)
                let cleanDomain = cleanDomainName(host)
                let processedDomain = processSpecialDomains(cleanDomain)

                // Ne pas inclure les domaines vides ou trop génériques (exception pour les domaines spéciaux courts)
                let specialShortDomains = ["x"]
                if !processedDomain.isEmpty
                    && (processedDomain.count > 2 || specialShortDomains.contains(processedDomain))
                {
                    domainFrequency[processedDomain, default: 0] += 1
                }
            }
        }

        // Trier par fréquence et prendre les 10 plus populaires
        let sortedDomains =
            domainFrequency
            .filter { $0.value >= 1 }  // Au moins 1 occurrence
            .sorted {
                if $0.value == $1.value {
                    return $0.key < $1.key  // Tri secondaire par nom pour stabilité
                }
                return $0.value > $1.value
            }
            .prefix(10)
            .map { $0.key }

        domains = Array(sortedDomains)
    }

    private func cleanDomainName(_ domain: String) -> String {
        var cleanDomain = domain.lowercased()

        // Enlever les préfixes communs
        let prefixesToRemove = ["www.", "m.", "mobile.", "app.", "api.", "cdn.", "static.", "media.", "open.", "vm.", "share.", ".fr"]
        for prefix in prefixesToRemove {
            if cleanDomain.hasPrefix(prefix) {
                cleanDomain = String(cleanDomain.dropFirst(prefix.count))
                break
            }
        }

        // Enlever les extensions courantes pour un affichage plus propre
        let extensionsToRemove = [
            ".com", ".fr", ".org", ".net", ".co", ".io", ".me", ".tv", ".be", ".de", ".uk", ".ca",
            ".au", ".eu", ".apple", ".pt",
        ]
        // Supprimer en cascade tant qu'un suffixe correspond (ex: ".com" puis ".apple")
        while let ext = extensionsToRemove.first(where: { cleanDomain.hasSuffix($0) }) {
            cleanDomain = String(cleanDomain.dropLast(ext.count))
        }

        // Nettoyer un éventuel point terminal (ex: "books.")
        if cleanDomain.hasSuffix(".") {
            cleanDomain.removeLast()
        }

        return cleanDomain
    }

    // MARK: - Display Name Mapping
    private func getDisplayName(for domain: String) -> String {
        // Gérer les cas spéciaux où l'affichage diffère du domaine de recherche
        switch domain.lowercased() {
        case "x":
            // Pour le domaine "x", on affiche "twitter" mais on recherche sur "t.co"
            return "twitter"
        default:
            return domain
        }
    }
    
    // MARK: - Search Term for Domain
    private func getSearchTermForDomain(_ domain: String) -> String {
        // Pour certains domaines, on doit rechercher sur l'URL originale, pas le domaine processé
        switch domain.lowercased() {
        case "x":
            // Pour Twitter/X, afficher "twitter" dans la barre de recherche (plus familier)
            return "twitter"
        default:
            return domain
        }
    }

    // MARK: - Numeric Sequence Detection
    private func isNumericSequence(_ word: String) -> Bool {
        // Vérifier si le mot est principalement composé de chiffres
        let digitCount = word.filter { $0.isNumber }.count
        let totalCount = word.count

        // Si plus de 70% du mot sont des chiffres, l'exclure
        // Cela filtre : "123456", "2024", "v1.2.3", "id12345", etc.
        return Double(digitCount) / Double(totalCount) > 0.7
    }

    // Mots vides à exclure (stop words français et anglais)
    private let stopWords: Set<String> = [
        // Français
        "le", "la", "les", "un", "une", "des", "du", "de", "et", "ou", "mais", "donc", "car", "ni",
        "or",
        "ce", "cette", "ces", "son", "sa", "ses", "mon", "ma", "mes", "ton", "ta", "tes", "notre",
        "nos", "votre", "vos", "leur", "leurs",
        "je", "tu", "il", "elle", "nous", "vous", "ils", "elles", "me", "te", "se", "lui", "eux",
        "dans", "sur", "avec", "par", "pour", "sans", "sous", "vers", "chez", "entre", "depuis",
        "pendant", "avant", "après",
        "que", "qui", "quoi", "dont", "où", "comment", "pourquoi", "quand", "combien",
        "très", "plus", "moins", "aussi", "encore", "déjà", "toujours", "jamais", "souvent",
        "parfois",
        "avoir", "être", "faire", "aller", "venir", "voir", "savoir", "pouvoir", "vouloir",
        "devoir", "dénichée",

        // Anglais
        "the", "a", "an", "and", "or", "but", "so", "for", "nor", "yet",
        "this", "that", "these", "those", "his", "her", "its", "my", "your", "our", "their",
        "i", "you", "he", "she", "it", "we", "they", "me", "him", "us", "them",
        "in", "on", "at", "by", "for", "with", "without", "under", "over", "through", "during",
        "before", "after", "above", "below",
        "what", "who", "when", "where", "why", "how", "which", "whose",
        "very", "more", "most", "less", "also", "too", "still", "already", "always", "never",
        "often", "sometimes",
        "have", "has", "had", "is", "are", "was", "were", "be", "been", "being", "do", "does",
        "did", "will", "would", "could", "should", "may", "might", "must", "can",
    ]

    // Termes techniques à exclure
    private let excludedTerms: Set<String> = [
        "www", "http", "https", "com", "org", "net", "fr", "html", "php", "asp", "jsp",
        "index", "page", "home", "main", "default", "admin", "login", "register",
        "file", "image", "photo", "video", "audio", "document", "pdf", "doc", "docx",
        "jpg", "jpeg", "png", "gif", "mp4", "mp3", "avi", "mov", "wav",
        "size", "width", "height", "length", "format", "type", "version", "update", "track", "pin",
        "open", "share", "status", "media", "es",
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
