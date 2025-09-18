//
//  URLDomainMapper.swift
//  PinpinShareExtension
//
//  Mapper des domaines URL vers les catégories de contenu
//  Séparé pour faciliter la maintenance et l'ajout de nouveaux domaines
//

import Foundation

class URLDomainMapper {
    
    static let shared = URLDomainMapper()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Mappe une URL vers une catégorie basée sur le domaine
    /// Retourne "misc" si aucun domaine connu n'est trouvé
    func mapURLToCategory(_ url: URL) -> String {
        let urlString = url.absoluteString.lowercased()
        
        // Vérifier chaque catégorie dans l'ordre de priorité
        if isMediaDomain(urlString) { return "media" }
        if isTravelDomain(urlString) { return "travel" }
        if isTechDomain(urlString) { return "tech" }
        if isFashionDomain(urlString) { return "fashion" }
        if isHomeDomain(urlString) { return "home" }
        if isFoodDomain(urlString) { return "food" }
        if isBeautyDomain(urlString) { return "beauty" }
        if isSportsDomain(urlString) { return "sports" }
        if isCarsDomain(urlString) { return "cars" }
        if isArtDomain(urlString) { return "art" }
        if isNatureDomain(urlString) { return "nature" }
        if isKidsDomain(urlString) { return "kids" }
        
        return "misc"
    }
    
    // MARK: - Private Domain Detection Methods
    
    private func isMediaDomain(_ urlString: String) -> Bool {
        let mediaDomains = [
            // Vidéo et streaming

            
            // Audio et musique
            "spotify.com", "apple.com/music", "music.apple.com", "deezer.com",
            "soundcloud.com", "bandcamp.com", "mixcloud.com",
            
            // Livres et lecture
            "books.apple.com", "itunes.apple.com/book", "audible.com",
            "kindle.amazon", "goodreads.com", "scribd.com",
            
            // Podcasts
            "podcasts.apple.com", "overcast.fm", "pocketcasts.com",
            
            // News et médias
            "lemonde.fr", "lefigaro.fr", "liberation.fr", "20minutes.fr",
            "franceinfo.fr", "bfmtv.com", "cnn.com", "bbc.com"
        ]
        
        return mediaDomains.contains { urlString.contains($0) }
    }
    
    private func isTravelDomain(_ urlString: String) -> Bool {
        let travelDomains = [
            // Hébergement
            "airbnb.com", "booking.com", "expedia.com", "hotels.com",
            "trivago.com", "agoda.com", "hostelworld.com",
            
            // Vols et transport aérien
            "kayak.com", "skyscanner.com", "momondo.com", "opodo.com",
            "airfrance.fr", "lufthansa.com", "ryanair.com", "easyjet.com",
            
            // Transport ferroviaire
            "sncf-connect.com", "trainline.com", "omio.com", "thetrainline.com",
            
            // Transport urbain et location
            "uber.com", "blablacar.com", "flixbus.com", "ouibus.com",
            "hertz.com", "avis.com", "europcar.com", "sixt.com",
            
            // Activités et guides
            "tripadvisor.com", "getyourguide.com", "viator.com",
            "klook.com", "civitatis.com"
        ]
        
        return travelDomains.contains { urlString.contains($0) }
    }
    
    private func isTechDomain(_ urlString: String) -> Bool {
        let techDomains = [
            // App stores
            "apps.apple.com", "play.google.com", "microsoft.com/store",
            
            // Développement
            "github.com", "gitlab.com", "stackoverflow.com", "developer.apple.com",
            "android.com", "firebase.google.com", "vercel.com", "netlify.com",
            
            // Logiciels et outils
            "microsoft.com", "adobe.com", "figma.com", "notion.so",
            "slack.com", "discord.com", "zoom.us", "teams.microsoft.com",
            
            // Cloud et services
            "aws.amazon.com", "cloud.google.com", "azure.microsoft.com",
            "dropbox.com", "icloud.com"
        ]
        
        return techDomains.contains { urlString.contains($0) }
    }
    
    private func isFashionDomain(_ urlString: String) -> Bool {
        let fashionDomains = [
            // Fast fashion
            "zara.com", "hm.com", "uniqlo.com", "mango.com", "gap.com",
            
            // Sport et streetwear
            "nike.com", "adidas.com", "puma.com", "reebok.com", "vans.com",
            "converse.com", "newbalance.com",
            
            // E-commerce mode
            "zalando.com", "asos.com", "boohoo.com", "prettylittlething.com",
            "shein.com", "aliexpress.com/category/fashion",
            
            // Seconde main
            "vinted.com", "vestiairecollective.com", "therealreal.com",
            "rebag.com", "fashionphile.com",
            
            // Mode française
            "galerieslafayette.com", "printemps.com", "3suisses.fr",
            "laredoute.fr", "kiabi.com"
        ]
        
        return fashionDomains.contains { urlString.contains($0) }
    }
    
    private func isHomeDomain(_ urlString: String) -> Bool {
        let homeDomains = [
            // Ameublement
            "ikea.com", "conforama.com", "but.fr", "maisons-du-monde.com",
            "westwing.com", "made.com", "habitat.fr",
            
            // Bricolage et jardinage
            "leroymerlin.com", "castorama.com", "bricomarche.com",
            "truffaut.com", "jardiland.com", "gamm-vert.com",
            
            // Décoration
            "ampm.fr", "laredoute.fr/maison", "maisonsdumonde.com",
            "zarahome.com", "hmhome.com",
            
            // E-commerce maison
            "amazon.com/home", "amazon.fr/maison", "cdiscount.com/maison",
            "fnac.com/maison"
        ]
        
        return homeDomains.contains { urlString.contains($0) }
    }
    
    private func isFoodDomain(_ urlString: String) -> Bool {
        let foodDomains = [
            // Livraison de repas
            "ubereats.com", "deliveroo.com", "justeat.fr", "foodora.com",
            "glovo.com", "stuart.com",
            
            // Restaurants et réservations
            "opentable.com", "lafourchette.com", "bookatable.com",
            "resy.com", "yelp.com",
            
            // Recettes et cuisine
            "marmiton.org", "750g.com", "cuisineaz.com", "ptitchef.com",
            "allrecipes.com", "epicurious.com",
            
            // Courses alimentaires
            "auchan.fr", "carrefour.fr", "leclerc.com", "intermarche.com",
            "monoprix.fr", "franprix.fr", "chronodrive.com",
            
            // Spécialités
            "picard.fr", "thiriet.com", "naturalia.fr"
        ]
        
        return foodDomains.contains { urlString.contains($0) }
    }
    
    private func isBeautyDomain(_ urlString: String) -> Bool {
        let beautyDomains = [
            // Parfumeries
            "sephora.com", "douglas.fr", "nocibe.fr", "marionnaud.fr",
            "origines-parfums.com",
            
            // Marques beauté
            "yves-rocher.fr", "loccitane.com", "kiehls.com", "clinique.com",
            "lancome.com", "chanel.com", "dior.com",
            
            // Parapharmacie
            "pharmacie-lafayette.com", "pharmasimple.com", "newpharma.fr",
            
            // Beauté en ligne
            "feelunique.com", "lookfantastic.com", "beautybay.com"
        ]
        
        return beautyDomains.contains { urlString.contains($0) }
    }
    
    private func isSportsDomain(_ urlString: String) -> Bool {
        let sportsDomains = [
            // Équipements sportifs
            "decathlon.fr", "intersport.fr", "gosport.fr", "sport2000.fr",
            "footlocker.com", "jdsports.com",
            
            // Sport en ligne
            "lequipe.fr", "eurosport.fr", "espn.com", "skysports.com",
            
            // Fitness
            "nike.com/training", "adidas.com/running", "strava.com",
            "myfitnesspal.com", "fitbit.com"
        ]
        
        return sportsDomains.contains { urlString.contains($0) }
    }
    
    private func isCarsDomain(_ urlString: String) -> Bool {
        let carsDomains = [
            // Vente automobile
            "leboncoin.fr/voitures", "lacentrale.fr", "autoscout24.fr",
            "paruvendu.fr/auto", "automobile.fr",
            
            // Constructeurs
            "peugeot.fr", "renault.fr", "citroen.fr", "bmw.fr",
            "mercedes-benz.fr", "audi.fr", "volkswagen.fr",
            
            // Services auto
            "midas.fr", "norauto.fr", "feu-vert.fr", "speedy.fr"
        ]
        
        return carsDomains.contains { urlString.contains($0) }
    }
    
    private func isArtDomain(_ urlString: String) -> Bool {
        let artDomains = [
            // Musées et galeries
            "louvre.fr", "orsay.fr", "centrepompidou.fr", "musee-rodin.fr",
            "metmuseum.org", "moma.org", "tate.org.uk",
            
            // Art en ligne
            "artsy.net", "saatchiart.com", "etsy.com/art",
            
            // Photographie
            "flickr.com", "500px.com", "behance.net", "dribbble.com"
        ]
        
        return artDomains.contains { urlString.contains($0) }
    }
    
    private func isNatureDomain(_ urlString: String) -> Bool {
        let natureDomains = [
            // Parcs et nature
            "parcsnationaux.fr", "reserves-naturelles.org",
            "nationalgeographic.com", "wwf.org",
            
            // Jardinage
            "rustica.fr", "gerbeaud.com", "promessedefleurs.com"
        ]
        
        return natureDomains.contains { urlString.contains($0) }
    }
    
    private func isKidsDomain(_ urlString: String) -> Bool {
        let kidsDomains = [
            // Jouets
            "toysrus.fr", "king-jouet.com", "oxybul.com", "fnac.com/jeux-jouets",
            "amazon.fr/jouets",
            
            // Vêtements enfants
            "jacadi.fr", "petit-bateau.fr", "okaidi.fr", "vertbaudet.fr",
            
            // Éducation
            "maxicours.com", "kartable.fr", "schoolmouv.fr"
        ]
        
        return kidsDomains.contains { urlString.contains($0) }
    }
}
