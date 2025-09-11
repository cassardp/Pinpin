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
        } else if isTravelURL(urlString) {
            return "travel"
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
            // Twitter/X
            "twitter.com", "www.twitter.com",
            "x.com", "www.x.com",
            
            // Meta (Facebook/Instagram/Threads)
            "facebook.com", "www.facebook.com", "fb.com", "m.facebook.com",
            "instagram.com", "www.instagram.com",
            "threads.net", "www.threads.net",
            "threads.com", "www.threads.com",
            
            // Pinterest
            "pinterest.com", "www.pinterest.com",
            "pin.it", "www.pin.it",
            "pinterest.fr", "pinterest.de", "pinterest.co.uk",
            
            // TikTok
            "tiktok.com", "www.tiktok.com",
            "vm.tiktok.com", "m.tiktok.com",
            
            // LinkedIn
            "linkedin.com", "www.linkedin.com",
            "lnkd.in", "www.lnkd.in",
            
            // Snapchat
            "snapchat.com", "www.snapchat.com",
            "snap.com", "www.snap.com",
            
            // Discord
            "discord.com", "www.discord.com",
            "discord.gg", "discordapp.com",
            
            // Reddit
            "reddit.com", "www.reddit.com",
            "redd.it", "old.reddit.com", "m.reddit.com",
            
            // Telegram
            "t.me", "telegram.me", "telegram.org",
            
            // WhatsApp
            "wa.me", "whatsapp.com", "www.whatsapp.com",
            "chat.whatsapp.com", "web.whatsapp.com",
            
            // Mastodon & Fediverse
            "mastodon.social", "mastodon.online", "mas.to",
            "mstdn.social", "fosstodon.org",
            
            // Autres plateformes
            "tumblr.com", "www.tumblr.com",
            "medium.com", "www.medium.com",
            "flickr.com", "www.flickr.com",
            "vimeo.com", "www.vimeo.com",
            "twitch.tv", "www.twitch.tv",
            "clubhouse.com", "www.clubhouse.com",
            "behance.net", "www.behance.net",
            "dribbble.com", "www.dribbble.com",
            "deviantart.com", "www.deviantart.com"
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
            // Plateformes principales
            "podcasts.apple.com", "spotify.com/show", "spotify.com/episode",
            "podcast.google.com", "podcasts.google.com",
            
            // Plateformes audio généralistes
            "soundcloud.com",
            
            // Hébergeurs de podcasts
            "anchor.fm", "buzzsprout.com", "podbean.com", "libsyn.com",
            "spreaker.com", "simplecast.com", "transistor.fm", "captivate.fm",
            "acast.com", "megaphone.fm", "redcircle.com", "whooshkaa.com",
            "podcast.co", "fireside.fm", "castos.com", "podscribe.com",
            
            // Applications d'écoute
            "overcast.fm", "pocketcasts.com", "castbox.fm", "castro.fm",
            "downcast.fm", "playerFM.com", "podcastaddict.com",
            "stitcher.com", "tunein.com", "iheart.com", "iheartradio.com",
            "radiofrance.fr", "radiocanada.ca", "bbc.co.uk/sounds",
            
            // Plateformes européennes
            "deezer.com/show", "deezer.com/episode", "podimo.com",
            "podtail.com", "podcast.de", "podcastone.com",
            
            // Plateformes spécialisées
            "luminary.link", "himalaya.com", "podchaser.com",
            "listen.stitcher.com", "podbay.fm", "podscribe.ai",
            "rss.com", "podcast.app", "podfollow.com"
        ]
        
        // Patterns spécifiques pour les podcasts
        let podcastPatterns = ["/podcast/", "/show/", "/episode/", "/listen/"]
        
        return podcastPlatforms.contains { urlString.contains($0) } ||
               podcastPatterns.contains { urlString.contains($0) }
    }
    
    private func isBookURL(_ urlString: String) -> Bool {
        let bookPlatforms = [
            // Plateformes principales
            "books.apple.com", "goodreads.com", "google.com/books",
            "kindle.amazon.com", "amazon.com/books", "amazon.com/kindle",
            
            // Livres audio
            "audible.com", "audible.fr", "audible.de", "audible.co.uk",
            "libro.fm", "downpour.com", "audiobooks.com",
            "scribd.com", "storytel.com", "bookbeat.com",
            
            // Liseuses et éditeurs
            "kobo.com", "rakuten.com/kobo", "barnesandnoble.com/nook",
            "play.google.com/books", "microsoft.com/books",
            
            // Bibliothèques numériques
            "overdrive.com", "hoopla.com", "libby.app", "cloudlibrary.com",
            "axis360.baker-taylor.com", "rbdigital.com",
            
            // Plateformes sociales de lecture
            "librarything.com", "shelfari.com", "anobii.com",
            "bookbub.com", "bookish.com", "litsy.com",
            
            // Plateformes d'abonnement
            "blinkist.com", "getabstract.com", "perlego.com",
            "bookmate.com", "nextory.com", "skoobe.de",
            
            // Éditeurs et librairies
            "hachette.com", "penguinrandomhouse.com", "harpercollins.com",
            "simonandschuster.com", "macmillan.com", "scholastic.com",
            "waterstones.com", "whsmith.co.uk", "blackwells.co.uk",
            "fnac.com/livre", "cultura.com/livres", "decitre.fr",
            "thalia.de", "hugendubel.de", "weltbild.de",
            
            // Plateformes indépendantes
            "smashwords.com", "draft2digital.com", "lulu.com",
            "bookfunnel.com", "prolificworks.com", "instafreebie.com",
            
            // Plateformes académiques
            "jstor.org", "springer.com", "wiley.com", "elsevier.com",
            "cambridge.org", "oxfordacademic.com", "taylorfrancis.com",
            
            // Plateformes gratuites
            "gutenberg.org", "archive.org", "openlibrary.org",
            "manybooks.net", "feedbooks.com", "planetebook.com"
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
    
    private func isTravelURL(_ urlString: String) -> Bool {
        let travelPlatforms = [
            // Hébergement
            "airbnb.com", "www.airbnb.com", "airbnb.fr", "airbnb.de", "airbnb.co.uk",
            "booking.com", "www.booking.com",
            "expedia.com", "www.expedia.com", "expedia.fr", "expedia.de", "expedia.co.uk",
            "hotels.com", "www.hotels.com",
            "trivago.com", "www.trivago.com", "trivago.fr", "trivago.de",
            "agoda.com", "www.agoda.com",
            "hostelworld.com", "www.hostelworld.com",
            "vrbo.com", "www.vrbo.com",
            "homeaway.com", "www.homeaway.com",
            "marriott.com", "www.marriott.com",
            "hilton.com", "www.hilton.com",
            "accor.com", "www.accor.com", "accorhotels.com",
            "ihg.com", "www.ihg.com",
            "hyatt.com", "www.hyatt.com",
            
            // Transport aérien
            "airfrance.com", "www.airfrance.com", "airfrance.fr",
            "lufthansa.com", "www.lufthansa.com",
            "britishairways.com", "www.britishairways.com",
            "klm.com", "www.klm.com", "klm.fr",
            "easyjet.com", "www.easyjet.com",
            "ryanair.com", "www.ryanair.com",
            "vueling.com", "www.vueling.com",
            "transavia.com", "www.transavia.com", "transavia.fr",
            "emirates.com", "www.emirates.com",
            "qantas.com", "www.qantas.com",
            "delta.com", "www.delta.com",
            "united.com", "www.united.com",
            "american.com", "www.aa.com",
            "skyscanner.com", "www.skyscanner.com", "skyscanner.fr",
            "kayak.com", "www.kayak.com", "kayak.fr",
            "momondo.com", "www.momondo.com", "momondo.fr",
            "opodo.com", "www.opodo.com", "opodo.fr",
            "edreams.com", "www.edreams.com", "edreams.fr",
            "govoyages.com", "www.govoyages.com",
            "lastminute.com", "www.lastminute.com", "lastminute.fr",
            
            // Transport ferroviaire
            "sncf-connect.com", "www.sncf-connect.com",
            "oui.sncf", "www.oui.sncf",
            "trainline.com", "www.trainline.com", "trainline.fr",
            "thetrainline.com", "www.thetrainline.com",
            "bahn.de", "www.bahn.de",
            "trenitalia.com", "www.trenitalia.com",
            "renfe.com", "www.renfe.com",
            "sbb.ch", "www.sbb.ch",
            "ns.nl", "www.ns.nl",
            "eurostar.com", "www.eurostar.com",
            "thalys.com", "www.thalys.com",
            
            // Location de voiture
            "hertz.com", "www.hertz.com", "hertz.fr",
            "avis.com", "www.avis.com", "avis.fr",
            "europcar.com", "www.europcar.com", "europcar.fr",
            "enterprise.com", "www.enterprise.com", "enterprise.fr",
            "sixt.com", "www.sixt.com", "sixt.fr",
            "budget.com", "www.budget.com", "budget.fr",
            "rentalcars.com", "www.rentalcars.com",
            "autoeurope.com", "www.autoeurope.com", "autoeurope.fr",
            
            // Croisières
            "royalcaribbean.com", "www.royalcaribbean.com",
            "msc.com", "www.msccruises.com", "www.msc.com",
            "costacruises.com", "www.costacruises.com",
            "ncl.com", "www.ncl.com",
            "princess.com", "www.princess.com",
            "celebrity.com", "www.celebritycruises.com",
            
            // Plateformes de voyage
            "tripadvisor.com", "www.tripadvisor.com", "tripadvisor.fr",
            "viator.com", "www.viator.com",
            "getyourguide.com", "www.getyourguide.com", "getyourguide.fr",
            "klook.com", "www.klook.com",
            "tiqets.com", "www.tiqets.com",
            "civitatis.com", "www.civitatis.com", "civitatis.fr",
            "musement.com", "www.musement.com",
            
            // Voyages organisés
            "thomascook.com", "www.thomascook.com",
            "tui.com", "www.tui.com", "tui.fr",
            "clubmed.com", "www.clubmed.com", "clubmed.fr",
            "nouvellefrontiere.fr", "www.nouvellefrontiere.fr",
            "promovacances.com", "www.promovacances.com",
            "fram.fr", "www.fram.fr",
            "lookea.com", "www.lookea.com",
            "jetcost.com", "www.jetcost.com", "jetcost.fr",
            
            // Transport urbain
            "uber.com", "www.uber.com",
            "lyft.com", "www.lyft.com",
            "bolt.eu", "www.bolt.eu",
            "freenow.com", "www.freenow.com",
            "kapten.com", "www.kapten.com",
            "blablacar.com", "www.blablacar.com", "blablacar.fr",
            
            // Autres services voyage
            "rome2rio.com", "www.rome2rio.com",
            "omio.com", "www.omio.com", "omio.fr",
            "wanderu.com", "www.wanderu.com",
            "busbud.com", "www.busbud.com",
            "flixbus.com", "www.flixbus.com", "flixbus.fr",
            "megabus.com", "www.megabus.com", "megabus.fr",
            "ouibus.com", "www.ouibus.com"
        ]
        
        // Patterns spécifiques pour le voyage
        let travelPatterns = [
            "/flight/", "/flights/", "/hotel/", "/hotels/",
            "/booking/", "/reservation/", "/travel/", "/trip/",
            "/destination/", "/cruise/", "/vacation/", "/holiday/"
        ]
        
        return travelPlatforms.contains { urlString.contains($0) } ||
               travelPatterns.contains { urlString.contains($0) }
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
        
        return false
    }
    
    private func isShowURL(_ urlString: String) -> Bool {
        // Plateformes de streaming principales
        let showPlatforms = [
            // Plateformes majeures US
            "netflix.com", "disneyplus.com", "hulu.com", "hbomax.com", "max.com",
            "paramountplus.com", "peacocktv.com", "apple.com/tv", "tv.apple.com",
            "primevideo.com",
            
            // Plateformes spécialisées US
            "crunchyroll.com", "funimation.com", "showtime.com", "starz.com",
            "epix.com", "discovery.com", "discoveryplus.com", "pluto.tv",
            "tubi.tv", "roku.com", "vudu.com", "fandangonow.com",
            "amc.com", "fxnetworks.com", "adultswim.com", "cartoonnetwork.com",
            
            // Plateformes françaises
            "canal-plus.com", "canalplus.com", "mycanal.fr", "mycan.al",
            "france.tv", "francetelevisions.fr", "arte.tv", "arte.fr",
            "ocs.fr", "molotov.tv", "salto.fr", "6play.fr",
            "tf1.fr", "tf1plus.fr", "m6.fr", "m6plus.fr",
            "rmc.fr", "bfmtv.com", "cnews.fr", "lci.fr",
            
            // Plateformes européennes
            "bbc.co.uk/iplayer", "itv.com", "channel4.com", "my5.tv",
            "sky.com", "nowtv.com", "britbox.com", "acorn.tv",
            "ard.de", "zdf.de", "rtl.de", "pro7.de", "sat1.de",
            "tvnow.de", "joyn.de", "magentasport.de", "dazn.com",
            "rai.it", "mediaset.it", "la7.it", "raiplay.it",
            "rtve.es", "atresplayer.com", "mitele.es", "movistarplus.es",
            "nos.nl", "npo.nl", "rtl.nl", "videoland.com",
            "svtplay.se", "tv4play.se", "viafree.se", "cmore.se",
            "nrk.no", "tv2.no", "viaplay.no", "discovery.no",
            
            // Plateformes asiatiques
            "viki.com", "dramafever.com", "kocowa.com", "wavve.com",
            "iqiyi.com", "youku.com", "bilibili.com", "tencent.com",
            "hotstar.com", "zee5.com", "sonyliv.com", "voot.com",
            
            // Plateformes latino-américaines
            "globoplay.globo.com", "telecineplay.com.br", "nowonline.com.br",
            "clarovideo.com", "blim.com", "paramount.com.mx",
            
            // Plateformes gratuites
            "youtube.com/tv", "dailymotion.com", "vimeo.com/ondemand",
            "twitch.tv", "mixer.com", "facebook.com/watch",
            "imdb.com/tv", "crackle.com", "popcornflix.com",
            "themoviedb.org", "www.themoviedb.org",
            "allocine.fr", "www.allocine.fr",
            
            // Plateformes sportives
            "espn.com", "espnplus.com", "nbcsports.com", "foxsports.com",
            "eurosport.com", "rmc.fr/sport", "lequipe.fr", "beinsports.com"
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
        
        // Vérification spécifique Amazon Prime Video
        if urlString.contains("amazon.com") {
            // Seulement si c'est Prime Video ou contient des patterns vidéo
            return urlString.contains("/prime/video") || 
                   urlString.contains("/gp/video") ||
                   showPatterns.contains { urlString.contains($0) }
        }
        
        // Vérification Apple TV
        if urlString.contains("apple.com") {
            return showPatterns.contains { urlString.contains($0) }
        }
        
        return false
    }
    
    // MARK: - Product Detection Helpers
    
    private func containsEcommerceHost(_ urlString: String) -> Bool {
        let ecommerceHosts = [
            // Marketplaces mondiaux
            "amazon.", "amzn.", "ebay.", "etsy.", "alibaba.", "aliexpress.",
            "mercadolibre.", "rakuten.", "jd.com", "tmall.", "taobao.",
            
            // Marketplaces européens
            "zalando.", "otto.", "cdiscount.", "fnac.", "darty.",
            "bol.com", "coolblue.", "mediamarkt.", "saturn.", "elgiganten.",
            "komplett.", "dustinhome.", "alternate.", "notebooksbilliger.",
            
            // Grandes surfaces US
            "walmart.", "target.", "bestbuy.", "homedepot.", "lowes.",
            "costco.", "samsclub.", "kroger.", "walgreens.", "cvs.",
            
            // Grandes surfaces européennes
            "carrefour.", "auchan.", "leclerc.", "intermarche.", "casino.",
            "tesco.", "asda.", "sainsburys.", "morrisons.", "argos.",
            "currys.", "johnlewis.", "marksandspencer.", "next.",
            "rewe.", "edeka.", "real.", "kaufland.", "lidl.", "aldi.",
            "coop.", "ica.", "rema1000.", "netto.",
            
            // Mode mondiale
            "nike.", "adidas.", "puma.", "underarmour.", "lululemon.",
            "hm.com", "zara.", "uniqlo.", "gap.", "oldnavy.",
            "bananarepublic.", "macys.", "nordstrom.", "zappos.",
            
            // Mode européenne
            "asos.", "boohoo.", "prettylittlething.", "missguided.",
            "aboutyou.", "zalando.", "lamoda.", "answear.",
            "kiabi.", "celio.", "jules.", "camaieu.", "promod.",
            "mango.", "bershka.", "pullandbear.", "stradivarius.",
            "massimodutti.", "oysho.", "uterque.",
            
            // Luxe
            "lvmh.", "chanel.", "hermes.", "gucci.", "prada.",
            "burberry.", "versace.", "armani.", "dolcegabbana.",
            "ysl.", "dior.", "fendi.", "bottegaveneta.",
            "net-a-porter.", "mrporter.", "farfetch.", "ssense.",
            "matchesfashion.", "mytheresa.", "luisaviaroma.",
            
            // Tech
            "apple.com/", "microsoft.com/", "samsung.com/", "sony.com/",
            "dell.", "hp.", "lenovo.", "asus.", "acer.", "msi.",
            "newegg.", "microcenter.", "bhphotovideo.", "adorama.",
            
            // Beauté
            "sephora.", "ulta.", "douglas.", "nocibe.", "marionnaud.",
            "boots.", "superdrug.", "feelunique.", "lookfantastic.",
            "beautybay.", "cultbeauty.", "spacenk.",
            
            // Maison & Jardin
            "ikea.", "wayfair.", "overstock.", "houzz.", "westelm.",
            "potterybarn.", "crateandbarrel.", "cb2.", "worldmarket.",
            "maisonsdumonde.", "but.", "conforama.", "fly.",
            "castorama.", "leroymerlin.", "bricorama.", "bricodepot.",
            "hornbach.", "bauhaus.", "obi.", "hagebau.", "toom.",
            "wickes.", "screwfix.", "toolstation.", "homebase.",
            
            // Alimentaire
            "instacart.", "freshdirect.", "peapod.", "shipt.",
            "ocado.", "tesco.", "asda.", "morrisons.", "sainsburys.",
            "monoprix.", "franprix.", "naturalia.", "biocoop.",
            "rewe.", "edeka.", "netto.", "penny.",
            
            // Électronique spécialisée
            "boulanger.", "rueducommerce.", "ldlc.", "materiel.net",
            "topachat.", "grosbill.", "pixmania.",
            "cyberport.", "computeruniverse.", "mindfactory.",
            "proshop.", "webhallen.", "inet.", "ellos.",
            
            // Livres & Culture
            "barnesandnoble.", "bookdepository.", "waterstones.",
            "whsmith.", "blackwells.", "foyles.",
            "fnac.", "cultura.", "decitre.", "mollat.",
            "thalia.", "hugendubel.", "weltbild.", "mayersche.",
            
            // Sport
            "decathlon.", "intersport.", "gosport.", "sportsdirect.",
            "jdsports.", "footlocker.", "sizeer.", "snipes.",
            "wiggle.", "chainreactioncycles.", "bike24.", "probikeshop.",
            
            // Jouets
            "toysrus.", "smythstoys.", "entertainer.", "argos.",
            "kingjouer.", "picwictoys.", "maxitoys.",
            "mytoys.", "spiele-max.", "br-online.",
            
            // Plateformes e-commerce
            "shopify.com", "myshopify.com", "bigcommerce.com", "woocommerce.com",
            "prestashop.", "magento.", "opencart.", "wix.com/stores",
            "squarespace.com/commerce", "etsy.com/shop",
            
            // Marketplaces spécialisées
            "reverb.", "discogs.", "catawiki.", "chrono24.",
            "vestiairecollective.", "rebag.", "fashionphile.",
            "stockx.", "goat.", "grailed.", "depop.", "vinted.",
            "leboncoin.fr", "www.leboncoin.fr",
            
            // Autres grandes enseignes
            "wish.", "joom.", "banggood.", "gearbest.", "lightinthebox.",
            "rosegal.", "zaful.", "romwe.", "shein.", "yesstyle."
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
    

}
