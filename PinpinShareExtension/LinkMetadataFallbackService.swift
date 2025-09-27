//
//  LinkMetadataFallbackService.swift
//  PinpinShareExtension
//
//  Service de fallback pour récupérer des images quand LinkPresentation échoue
//

import Foundation
import UIKit
import UniformTypeIdentifiers

class LinkMetadataFallbackService {
    
    static let shared = LinkMetadataFallbackService()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Tente de récupérer une image depuis une URL quand LinkPresentation échoue
    func fetchImageFallback(from url: URL, completion: @escaping (UIImage?) -> Void) {
        // Vérifier si c'est déjà une URL d'image directe
        if isDirectImageURL(url) {
            downloadImageDirectly(from: url, completion: completion)
            return
        }
        
        // Tenter de récupérer l'Open Graph image
        fetchOpenGraphImage(from: url, completion: completion)
    }
    
    // MARK: - Private Methods
    
    /// Vérifie si l'URL pointe directement vers une image
    private func isDirectImageURL(_ url: URL) -> Bool {
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "webp", "bmp", "tiff", "svg"]
        let pathExtension = url.pathExtension.lowercased()
        return imageExtensions.contains(pathExtension)
    }
    
    /// Télécharge une image directement depuis son URL
    private func downloadImageDirectly(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data,
                      error == nil,
                      let image = UIImage(data: data) else {
                    completion(nil)
                    return
                }
                completion(image)
            }
        }.resume()
    }
    
    /// Tente de récupérer une image depuis le HTML de la page
    private func fetchOpenGraphImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        // Configuration de la requête avec User-Agent pour éviter les blocages
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10.0
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data,
                  error == nil,
                  let htmlString = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // 1. Essayer Open Graph d'abord
            if let ogImageURL = self?.extractOpenGraphImageURL(from: htmlString, baseURL: url) {
                self?.downloadImageDirectly(from: ogImageURL) { image in
                    if image != nil {
                        completion(image)
                        return
                    }
                    // Si OG échoue, essayer les grosses images
                    self?.findLargestImageInHTML(htmlString, baseURL: url, completion: completion)
                }
                return
            }
            
            // 2. Pas d'Open Graph, chercher les grosses images directement
            self?.findLargestImageInHTML(htmlString, baseURL: url, completion: completion)
        }.resume()
    }
    
    /// Extrait l'URL de l'image Open Graph depuis le HTML
    private func extractOpenGraphImageURL(from html: String, baseURL: URL) -> URL? {
        // Rechercher les balises meta Open Graph pour les images
        let ogImagePatterns = [
            #"<meta\s+property=["\']og:image["\'][^>]*content=["\']([^"\']+)["\'][^>]*>"#,
            #"<meta\s+content=["\']([^"\']+)["\'][^>]*property=["\']og:image["\'][^>]*>"#,
            #"<meta\s+name=["\']twitter:image["\'][^>]*content=["\']([^"\']+)["\'][^>]*>"#,
            #"<meta\s+content=["\']([^"\']+)["\'][^>]*name=["\']twitter:image["\'][^>]*>"#
        ]
        
        for pattern in ogImagePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                
                let imageURLString = String(html[range])
                
                // Convertir en URL absolue si nécessaire
                if let imageURL = URL(string: imageURLString) {
                    return imageURL
                } else if let relativeURL = URL(string: imageURLString, relativeTo: baseURL) {
                    return relativeURL.absoluteURL
                }
            }
        }
        
        return nil
    }
    
    /// Trouve la plus grosse image probable dans le HTML
    private func findLargestImageInHTML(_ html: String, baseURL: URL, completion: @escaping (UIImage?) -> Void) {
        let imageURLs = extractImageURLsFromHTML(html, baseURL: baseURL)
        
        // Trier les images par probabilité d'être intéressantes
        let sortedImages = prioritizeImageURLs(imageURLs)
        
        // Essayer les images dans l'ordre de priorité
        tryImageURLsSequentially(sortedImages, completion: completion)
    }
    
    /// Extrait toutes les URLs d'images du HTML
    private func extractImageURLsFromHTML(_ html: String, baseURL: URL) -> [URL] {
        var imageURLs: [URL] = []
        
        // Pattern pour les balises img avec différents attributs
        let imgPatterns = [
            #"<img[^>]+src=["\']([^"\']+)["\'][^>]*>"#,
            #"<img[^>]+data-src=["\']([^"\']+)["\'][^>]*>"#, // Lazy loading
            #"<img[^>]+data-original=["\']([^"\']+)["\'][^>]*>"#, // Lazy loading
            #"<img[^>]+data-zoom=["\']([^"\']+)["\'][^>]*>"#, // Images zoom produit
            #"<img[^>]+data-large=["\']([^"\']+)["\'][^>]*>"#, // Images large produit
            #"background-image:\s*url\(["\']?([^"\')\s]+)["\']?\)"#, // CSS background
            #"<picture[^>]*>.*?<source[^>]+srcset=["\']([^"\']+)["\'][^>]*>.*?</picture>"#, // Picture element
            // Patterns spécifiques e-commerce
            #"<img[^>]*class=["\'][^"\']*product[^"\']*["\'][^>]*src=["\']([^"\']+)["\'][^>]*>"#,
            #"<img[^>]*class=["\'][^"\']*item[^"\']*["\'][^>]*src=["\']([^"\']+)["\'][^>]*>"#,
            #"<img[^>]*id=["\'][^"\']*product[^"\']*["\'][^>]*src=["\']([^"\']+)["\'][^>]*>"#,
        ]
        
        for pattern in imgPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
                let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))
                
                for match in matches {
                    if let range = Range(match.range(at: 1), in: html) {
                        let urlString = String(html[range])
                        
                        // Nettoyer l'URL (enlever les paramètres srcset)
                        let cleanURL = urlString.components(separatedBy: " ").first ?? urlString
                        
                        if let imageURL = URL(string: cleanURL) {
                            imageURLs.append(imageURL)
                        } else if let relativeURL = URL(string: cleanURL, relativeTo: baseURL) {
                            imageURLs.append(relativeURL.absoluteURL)
                        }
                    }
                }
            }
        }
        
        return imageURLs
    }
    
    /// Priorise les URLs d'images selon leur probabilité d'être intéressantes
    private func prioritizeImageURLs(_ urls: [URL]) -> [URL] {
        return urls.sorted { url1, url2 in
            let score1 = calculateImageScore(url1)
            let score2 = calculateImageScore(url2)
            return score1 > score2
        }
    }
    
    /// Calcule un score pour une URL d'image (plus élevé = plus intéressant)
    private func calculateImageScore(_ url: URL) -> Int {
        let urlString = url.absoluteString.lowercased()
        let path = url.path.lowercased()
        
        var score = 0
        
        // BONUS SPÉCIAL E-COMMERCE (priorité maximale)
        let ecommerceKeywords = ["product", "item", "catalog", "catalogue", "shop", "store", "buy", "purchase", "cart", "checkout", "sku", "variant", "model"]
        for keyword in ecommerceKeywords {
            if urlString.contains(keyword) {
                score += 25 // Score très élevé pour e-commerce
            }
        }
        
        // Images de produit spécifiques
        let productImageKeywords = ["product-image", "item-image", "main-product", "product-photo", "item-photo", "product_image", "item_image", "productimage", "itemimage"]
        for keyword in productImageKeywords {
            if urlString.contains(keyword) {
                score += 30 // Score maximum pour images produit explicites
            }
        }
        
        // Patterns e-commerce courants dans les URLs
        let ecommercePatterns = [
            "products/", "items/", "catalog/", "catalogue/", "/p/", "/product/", "/item/",
            "media/catalog/", "images/products/", "assets/products/", "cdn/shop/"
        ]
        for pattern in ecommercePatterns {
            if urlString.contains(pattern) {
                score += 20
            }
        }
        
        // Bonus pour les mots-clés positifs généraux
        let positiveKeywords = ["hero", "banner", "main", "featured", "cover", "header", "large", "big", "primary", "article", "content", "post", "gallery"]
        for keyword in positiveKeywords {
            if urlString.contains(keyword) {
                score += 10
            }
        }
        
        // Malus pour les mots-clés négatifs
        let negativeKeywords = ["icon", "favicon", "logo", "thumb", "small", "mini", "avatar", "profile", "button", "badge", "ad", "ads", "banner-ad", "pixel", "tracking"]
        for keyword in negativeKeywords {
            if urlString.contains(keyword) {
                score -= 15
            }
        }
        
        // Bonus pour les dimensions dans l'URL
        let dimensionPattern = #"(\d{3,4})[x×](\d{3,4})"#
        if let regex = try? NSRegularExpression(pattern: dimensionPattern),
           let match = regex.firstMatch(in: urlString, range: NSRange(urlString.startIndex..., in: urlString)) {
            // Extraire les dimensions
            if let widthRange = Range(match.range(at: 1), in: urlString),
               let heightRange = Range(match.range(at: 2), in: urlString),
               let width = Int(urlString[widthRange]),
               let height = Int(urlString[heightRange]) {
                
                let area = width * height
                if area > 200000 { // > 400x500 environ
                    score += 20
                } else if area > 50000 { // > 200x250 environ
                    score += 10
                } else {
                    score -= 5 // Petites images
                }
            }
        }
        
        // Bonus pour les extensions d'images de qualité
        if path.hasSuffix(".jpg") || path.hasSuffix(".jpeg") {
            score += 5
        } else if path.hasSuffix(".png") {
            score += 3
        } else if path.hasSuffix(".webp") {
            score += 7 // Format moderne, souvent de qualité
        }
        
        // Malus pour les images très probablement petites
        if path.contains("16x16") || path.contains("32x32") || path.contains("64x64") {
            score -= 20
        }
        
        // BONUS SPÉCIAL pour les plateformes e-commerce connues
        let ecommerceDomains = [
            "amazon", "ebay", "shopify", "etsy", "alibaba", "aliexpress", "wish", "mercari",
            "zalando", "asos", "hm.com", "zara", "uniqlo", "nike", "adidas", "apple.com",
            "fnac", "cdiscount", "darty", "boulanger", "leroy-merlin", "ikea", "decathlon",
            "sephora", "douglas", "marionnaud", "nocibe", "yves-rocher", "loccitane",
            "carrefour", "leclerc", "auchan", "intermarche", "monoprix", "franprix"
        ]
        
        for domain in ecommerceDomains {
            if urlString.contains(domain) {
                score += 15 // Bonus pour plateformes e-commerce connues
                break
            }
        }
        
        // Bonus supplémentaire si c'est clairement une fiche produit
        if isProductPageURL(urlString) {
            score += 20
        }
        
        return score
    }
    
    /// Détecte si l'URL semble être une fiche produit
    private func isProductPageURL(_ urlString: String) -> Bool {
        let productPagePatterns = [
            "/dp/", "/gp/product/", "/p/", "/product/", "/item/", "/products/",
            "/article/", "/ref=", "pid=", "productid=", "itemid=", "sku="
        ]
        
        return productPagePatterns.contains { urlString.contains($0) }
    }
    
    /// Essaie les URLs d'images de manière séquentielle
    private func tryImageURLsSequentially(_ urls: [URL], completion: @escaping (UIImage?) -> Void) {
        guard !urls.isEmpty else {
            completion(nil)
            return
        }
        
        let currentURL = urls[0]
        let remainingURLs = Array(urls.dropFirst())
        
        downloadImageDirectly(from: currentURL) { [weak self] image in
            if let image = image, self?.isImageLargeEnough(image) == true {
                completion(image)
            } else {
                // Essayer la suivante
                self?.tryImageURLsSequentially(remainingURLs, completion: completion)
            }
        }
    }
    
    /// Vérifie si une image est assez grande pour être intéressante
    private func isImageLargeEnough(_ image: UIImage) -> Bool {
        let minArea: CGFloat = 10000 // 100x100 minimum
        let area = image.size.width * image.size.height
        return area >= minArea
    }
    
}
