//
//  ContentTypeDetector.swift
//  NeeedShareExtension
//
//  Service pour détecter automatiquement le type de contenu basé sur l'URL
//  Version pour l'extension de partage
//

import Foundation

class ContentTypeDetector {
    
    static let shared = ContentTypeDetector()
    
    private init() {}
    
    // MARK: - Public Methods
    
    func detectContentType(from url: URL) -> String {
        let urlString = url.absoluteString.lowercased()
        
        // Ordre de priorité pour la détection
        if isSocialURL(urlString) {
            return "social"
        } else if isShowURL(urlString) {
            return "show"
        } else if isVideoURL(urlString) {
            return "video"
        } else if isMusicURL(urlString) {
            return "music"
        } else if isPodcastURL(urlString) {
            return "podcast"
        } else if isBookURL(urlString) {
            return "book"
        } else if isAppURL(urlString) {
            return "app"
        } else if isImageURL(urlString) {
            return "image"
        } else if isProductURL(urlString) {
            return "product"
        } else {
            return "webpage"
        }
    }
    
    // MARK: - Private Detection Methods
    
    private func isSocialURL(_ urlString: String) -> Bool {
        // Vérification précise des domaines pour éviter les faux positifs
        let url = URL(string: urlString)
        let host = url?.host?.lowercased() ?? ""
        
        let socialHosts = [
            "twitter.com", "www.twitter.com",
            "x.com", "www.x.com",
            "instagram.com", "www.instagram.com",
            "pinterest.com", "www.pinterest.com",
            "pin.it", "www.pin.it",
            "tiktok.com", "www.tiktok.com",
            "threads.net", "www.threads.net",
            "threads.com", "www.threads.com"
        ]
        
        return socialHosts.contains(host)
    }
    
    private func isVideoURL(_ urlString: String) -> Bool {
        // Plateformes vidéo
        if urlString.contains("youtube.com") || urlString.contains("youtu.be") {
            return true
        }
        
        // Extensions vidéo
        if urlString.hasSuffix(".mp4") || urlString.hasSuffix(".mov") || 
           urlString.hasSuffix(".avi") || urlString.hasSuffix(".mkv") {
            return true
        }
        
        return false
    }
    
    private func isMusicURL(_ urlString: String) -> Bool {
        let musicPlatforms = [
            "spotify.com", "music.apple.com", "soundcloud.com",
            "deezer.com", "tidal.com", "bandcamp.com"
        ]
        
        return musicPlatforms.contains { urlString.contains($0) }
    }
    
    private func isPodcastURL(_ urlString: String) -> Bool {
        let podcastPlatforms = [
            "podcasts.apple.com", "spotify.com/show", "spotify.com/episode",
            "soundcloud.com", "anchor.fm", "buzzsprout.com", "podbean.com",
            "castbox.fm", "overcast.fm", "pocketcasts.com", "stitcher.com",
            "tunein.com", "iheart.com", "audible.com", "podcast.google.com"
        ]
        
        // Patterns spécifiques pour les podcasts
        let podcastPatterns = ["/podcast/", "/show/", "/episode/", "/listen/"]
        
        return podcastPlatforms.contains { urlString.contains($0) } ||
               podcastPatterns.contains { urlString.contains($0) }
    }
    
    private func isBookURL(_ urlString: String) -> Bool {
        let bookPlatforms = [
            "books.apple.com", "goodreads.com", "google.com/books",
            "audible.com", "scribd.com", "kindle.amazon.com", "kobo.com",
            "librarything.com", "bookbub.com", "overdrive.com", "hoopla.com",
            "blinkist.com", "storytel.com", "bookmate.com"
        ]
        
        // Patterns spécifiques pour les livres
        let bookPatterns = ["/book/", "/books/", "/ebook/", "/audiobook/"]
        
        // Détection Amazon spécifique pour les livres
        if urlString.contains("amazon.com") {
            // Patterns spécifiques Amazon pour livres
            return urlString.contains("/dp/B0") || // Les livres Kindle commencent souvent par B0
                   urlString.contains("/books/") ||
                   urlString.contains("/kindle-ebooks/") ||
                   urlString.contains("/audible/") ||
                   urlString.contains("node=283155") || // Catégorie Books sur Amazon
                   urlString.contains("node=154606011") // Catégorie Kindle Store
        }
        
        return bookPlatforms.contains { urlString.contains($0) } ||
               bookPatterns.contains { urlString.contains($0) }
    }
    
    private func isAppURL(_ urlString: String) -> Bool {
        return urlString.contains("apps.apple.com") || urlString.contains("play.google.com")
    }
    
    private func isImageURL(_ urlString: String) -> Bool {
        let imageExtensions = [".jpg", ".jpeg", ".png", ".gif", ".webp", ".svg"]
        return imageExtensions.contains { urlString.hasSuffix($0) }
    }
    
    private func isProductURL(_ urlString: String) -> Bool {
        // Sites e-commerce majeurs
        if containsEcommerceHost(urlString) {
            return true
        }
        
        // Patterns d'URLs produits
        if containsProductPattern(urlString) {
            return true
        }
        
        // Détections spécifiques par plateforme
        if hasSpecificProductPattern(urlString) {
            return true
        }
        
        return false
    }
    
    private func isShowURL(_ urlString: String) -> Bool {
        // Plateformes de streaming principales
        let showPlatforms = [
            // Plateformes majeures
            "netflix.com", "disneyplus.com", "hulu.com", "hbomax.com", "max.com",
            "paramountplus.com", "peacocktv.com", "apple.com/tv", "tv.apple.com",
            // Amazon Prime Video
            "amazon.com/prime/video", "amazon.com/gp/video", "primevideo.com",
            // Autres plateformes
            "crunchyroll.com", "funimation.com", "showtime.com", "starz.com",
            "epix.com", "discovery.com", "discoveryplus.com", "pluto.tv",
            // Plateformes internationales
            "canal-plus.com", "canalplus.com", "france.tv", "arte.tv",
            "ocs.fr", "molotov.tv", "salto.fr", "tf1.fr", "m6.fr", "mycan.al"
        ]
        
        // Vérification des plateformes
        for platform in showPlatforms {
            if urlString.contains(platform) {
                return true
            }
        }
        
        // Patterns spécifiques pour les URLs de séries/émissions
        let showPatterns = [
            "/series/", "/show/", "/episode/", "/season/",
            "/tv/", "/watch/", "/stream/", "/movie/"
        ]
        
        // Vérification des patterns si on est sur une plateforme vidéo
        if urlString.contains("amazon.com") || urlString.contains("apple.com") {
            return showPatterns.contains { urlString.contains($0) }
        }
        
        return false
    }
    
    // MARK: - Product Detection Helpers
    
    private func containsEcommerceHost(_ urlString: String) -> Bool {
        let ecommerceHosts = [
            // Marketplaces
            "amazon.", "amzn.", "ebay.", "etsy.", "alibaba.", "aliexpress.",
            // Grandes surfaces
            "walmart.", "target.", "bestbuy.", "homedepot.", "lowes.",
            "ikea.", "wayfair.", "overstock.", "costco.", "samsclub.",
            // Mode
            "macys.", "nordstrom.", "zappos.", "asos.", "hm.com",
            "zara.", "uniqlo.", "gap.", "oldnavy.", "bananarepublic.",
            "nike.", "adidas.", "puma.", "underarmour.", "lululemon.",
            // Beauté
            "sephora.", "ulta.", "cvs.", "walgreens.", "rite-aid.",
            // Tech
            "apple.com/", "microsoft.com/", "samsung.com/", "sony.com/",
            // Plateformes e-commerce
            "shopify.com", "myshopify.com", "bigcommerce.com", "woocommerce.com"
        ]
        
        return ecommerceHosts.contains { urlString.contains($0) }
    }
    
    private func containsProductPattern(_ urlString: String) -> Bool {
        let productPatterns = [
            "/product/", "/products/", "/item/", "/items/",
            "/p/", "/dp/", "/pd/", "/sku/",
            "/buy/", "/shop/", "/store/",
            "/collections/", "/category/", "/categories/",
            "/catalog/", "/boutique/", "/marketplace/"
        ]
        
        return productPatterns.contains { urlString.contains($0) }
    }
    
    private func hasSpecificProductPattern(_ urlString: String) -> Bool {
        // Amazon
        if urlString.contains("amazon.") && (urlString.contains("/dp/") || urlString.contains("/gp/product/")) {
            return true
        }
        
        // eBay
        if urlString.contains("ebay.") && urlString.contains("/itm/") {
            return true
        }
        
        // Shopify stores
        if urlString.contains("myshopify.com") || 
           (urlString.contains("/products/") && !urlString.contains("blog")) ||
           (urlString.contains("/collections/") && urlString.contains("/products/")) {
            return true
        }
        
        return false
    }
}
