//
//  VisionLabelMapper.swift
//  PinpinShareExtension
//
//  Mapper intelligent des 1300+ labels Vision vers les nouvelles catégories
//

import Foundation

class VisionLabelMapper {
    
    static let shared = VisionLabelMapper()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Mappe un label Vision vers une catégorie
    func mapLabelToCategory(_ label: String) -> String {
        let normalizedLabel = label.lowercased()
        
        // Ordre de priorité pour éviter les conflits
        if isFashionLabel(normalizedLabel) { return "fashion" }
        if isHomeLabel(normalizedLabel) { return "home" }
        if isFoodLabel(normalizedLabel) { return "food" }
        if isTravelLabel(normalizedLabel) { return "travel" }
        if isNatureLabel(normalizedLabel) { return "nature" }
        if isTechLabel(normalizedLabel) { return "tech" }
        if isArtLabel(normalizedLabel) { return "art" }
        if isSportsLabel(normalizedLabel) { return "sports" }
        if isCarsLabel(normalizedLabel) { return "cars" }
        if isBeautyLabel(normalizedLabel) { return "beauty" }
        if isMediaLabel(normalizedLabel) { return "media" }
        if isKidsLabel(normalizedLabel) { return "kids" }
        
        return "misc" // Fallback
    }
    
    /// Mappe plusieurs labels et retourne la catégorie la plus probable
    func mapLabelsToCategory(_ labels: [String]) -> String {
        let categories = labels.map { mapLabelToCategory($0) }
        
        // Compte les occurrences de chaque catégorie
        var categoryCount: [String: Int] = [:]
        for category in categories {
            categoryCount[category, default: 0] += 1
        }
        
        // Retourne la catégorie la plus fréquente (ou "misc" si égalité)
        return categoryCount.max(by: { $0.value < $1.value })?.key ?? "misc"
    }
    
    /// Vérifie si un label est trop générique pour être utile à la classification
    private func isGenericLabel(_ label: String) -> Bool {
        let genericLabels = [
            "structure", "wood_processed", "liquid", "water", "water_body", "machine",
        ]
        
        let normalizedLabel = label.lowercased()
        return genericLabels.contains(normalizedLabel)
    }
    
    /// Structure pour représenter un label avec son score de confiance
    struct LabelWithConfidence {
        let label: String
        let confidence: Float
    }
    
    /// Mappe plusieurs labels avec leurs scores de confiance et retourne la catégorie la plus probable
    /// La classification est pondérée par les scores de confiance
    func mapLabelsWithConfidenceToCategory(_ labelsWithConfidence: [LabelWithConfidence]) -> String {
        // Filtrer d'abord les labels trop génériques
        let filteredLabels = labelsWithConfidence.filter { !isGenericLabel($0.label) }
        
        // Si tous les labels sont génériques, utiliser les originaux (fallback)
        let labelsToAnalyze = filteredLabels.isEmpty ? labelsWithConfidence : filteredLabels
        
        // Seuil de confiance très élevée pour classification immédiate
        let highConfidenceThreshold: Float = 0.85
        
        // Vérifier s'il y a un label avec une confiance très élevée
        for item in labelsToAnalyze {
            if item.confidence >= highConfidenceThreshold {
                let category = mapLabelToCategory(item.label)
                // Si la catégorie n'est pas "misc", l'utiliser immédiatement
                if category != "misc" {
                    return category
                }
            }
        }
        
        // Seuil minimum de confiance pour éviter le bruit (labels trop incertains)
        let minimumConfidenceThreshold: Float = 0.3
        
        // Filtrer les labels avec une confiance suffisante (sur les labels déjà filtrés)
        let reliableLabels = labelsToAnalyze.filter { $0.confidence >= minimumConfidenceThreshold }
        
        // Si aucun label fiable, utiliser tous les labels filtrés (fallback)
        let labelsToProcess = reliableLabels.isEmpty ? labelsToAnalyze : reliableLabels
        
        // Pondération par score de confiance
        var categoryScores: [String: Float] = [:]
        
        for item in labelsToProcess {
            let category = mapLabelToCategory(item.label)
            
            // Applique une pondération exponentielle pour favoriser les hauts scores
            // Un score de 0.9 aura beaucoup plus de poids qu'un score de 0.3
            let weightedScore = pow(item.confidence, 2.0) // Pondération quadratique
            
            categoryScores[category, default: 0.0] += weightedScore
        }
        
        // Retourne la catégorie avec le score pondéré le plus élevé
        return categoryScores.max(by: { $0.value < $1.value })?.key ?? "misc"
    }
    
    // MARK: - Private Category Detection Methods
    
    private func isFashionLabel(_ label: String) -> Bool {
        let fashionKeywords = [
            // Vêtements
            "clothing", "jacket", "jeans", "suit", "dress", "shirt", "pants", "skirt", "blouse", "sweater",
            "hoodie", "coat", "blazer", "vest", "cardigan", "tuxedo", "gown", "robe", "uniform", "apron",
            "bathrobe", "kimono", "sari", "kilt", "poncho", "cloak", "leotard", "costume", "wedding_dress",
            
            // Chaussures
            "shoes", "boot", "sneaker", "sandal", "high_heel", "loafer", "moccasin", "flipper",
            
            // Accessoires
            "hat", "cap", "beanie", "fedora", "cowboy_hat", "sunhat", "sombrero", "tiara", "helmet",
            "bag", "purse", "backpack", "briefcase", "suitcase", "luggage", "wallet",
            "jewelry", "necklace", "bracelet", "ring", "earrings", "watch", "brooch",
            "belt", "tie", "bowtie", "necktie", "scarf", "glove", "mitten", "sock",
            "sunglasses", "eyeglasses", "goggles",
            
            // Mode spécifique
            "fashion", "style", "runway", "model", "designer", "boutique", "wardrobe"
        ]
        
        return fashionKeywords.contains { keyword in
            // Correspondance exacte ou avec séparateurs
            label == keyword || 
            label.hasPrefix(keyword + " ") || 
            label.hasSuffix(" " + keyword) || 
            label.contains(" " + keyword + " ")
        }
    }
    
    private func isHomeLabel(_ label: String) -> Bool {
        let homeKeywords = [
            // Mobilier
            "furniture", "chair", "table", "sofa", "bed", "desk", "cabinet", "shelf", "bookshelf",
            "armchair", "bench", "stool", "dresser", "wardrobe", "closet", "nightstand",
            "folding_chair", "swivel_chair", "high_chair", "chaise",
            
            // Pièces
            "room", "bedroom", "living_room", "kitchen", "bathroom", "dining_room", "office",
            "garage", "basement", "attic", "balcony", "porch", "patio", "deck",
            
            // Électroménager
            "appliance", "refrigerator", "oven", "microwave", "dishwasher", "washing_machine",
            "dryer", "vacuum", "blender", "toaster", "coffee_maker", "kettle",
            
            // Décoration
            "lamp", "light", "chandelier", "candle", "candlestick", "mirror", "picture", "frame",
            "vase", "plant", "flower", "bouquet", "decoration", "ornament", "wreath",
            "curtain", "blind", "pillow", "cushion", "blanket", "rug", "carpet",
            
            // Ustensiles et vaisselle
            "cookware", "pan", "pot", "bowl", "plate", "cup", "mug", "glass", "bottle",
            "fork", "knife", "spoon", "chopsticks", "cutting_board", "grater", "whisk",
            "ladle", "spatula", "tongs", "opener",
            
            // Maison générale
            "house", "home", "apartment", "building", "door", "window", "roof", "chimney",
            "stairs", "elevator", "hallway", "corridor", "floor", "ceiling", "wall"
        ]
        
        return homeKeywords.contains { keyword in
            // Correspondance exacte ou avec séparateurs
            label == keyword || 
            label.hasPrefix(keyword + " ") || 
            label.hasSuffix(" " + keyword) || 
            label.contains(" " + keyword + " ")
        }
    }
    
    private func isFoodLabel(_ label: String) -> Bool {
        let foodKeywords = [
            // Catégorie générale
            "food", "meal", "dish", "cuisine", "recipe", "cooking", "baking",
            
            // Fruits
            "fruit", "apple", "banana", "orange", "grape", "strawberry", "blueberry", "raspberry",
            "cherry", "peach", "pear", "plum", "apricot", "kiwi", "mango", "pineapple",
            "watermelon", "melon", "cantaloupe", "honeydew", "lemon", "lime", "grapefruit",
            "avocado", "coconut", "papaya", "guava", "passionfruit", "lychee", "rambutan",
            "durian", "persimmon", "pomegranate", "fig", "berry", "citrus",
            
            // Légumes
            "vegetable", "carrot", "broccoli", "spinach", "lettuce", "tomato", "cucumber",
            "pepper", "onion", "garlic", "potato", "corn", "pea", "bean", "celery",
            "asparagus", "artichoke", "eggplant", "zucchini", "squash", "pumpkin",
            "beet", "radish", "turnip", "cabbage", "cauliflower", "brussels_sprouts",
            
            // Viandes et protéines
            "meat", "beef", "pork", "chicken", "turkey", "duck", "lamb", "fish", "salmon",
            "tuna", "shrimp", "lobster", "crab", "oyster", "clam", "mussel", "scallop",
            "egg", "cheese", "milk", "yogurt", "butter",
            
            // Plats préparés
            "pizza", "burger", "sandwich", "salad", "soup", "pasta", "spaghetti", "noodles",
            "rice", "bread", "cake", "pie", "cookie", "muffin", "donut", "bagel",
            "pancake", "waffle", "cereal", "oatmeal", "yogurt", "ice_cream", "chocolate",
            "candy", "gum", "popcorn", "pretzel", "chips", "fries", "nachos",
            
            // Boissons
            "drink", "water", "juice", "soda", "coffee", "tea", "wine", "beer", "cocktail",
            "smoothie", "milkshake", "lemonade",
            
            // Épices et condiments
            "spice", "herb", "salt", "pepper", "sugar", "honey", "syrup", "sauce",
            "mustard", "ketchup", "mayo", "vinegar", "oil"
        ]
        
        return foodKeywords.contains { keyword in
            // Correspondance exacte ou avec séparateurs
            label == keyword || 
            label.hasPrefix(keyword + " ") || 
            label.hasSuffix(" " + keyword) || 
            label.contains(" " + keyword + " ")
        }
    }
    
    private func isTravelLabel(_ label: String) -> Bool {
        let travelKeywords = [
            // Transport
            "airplane", "aircraft", "airport", "flight", "airline", "jet", "helicopter",
            "train", "railway", "station", "subway", "metro", "tram", "bus", "taxi",
            "ship", "boat", "cruise", "ferry", "yacht", "sailboat", "speedboat",
            "car", "rental", "highway", "road", "bridge", "tunnel",
            
            // Hébergement
            "hotel", "motel", "resort", "hostel", "inn", "lodge", "cabin", "villa",
            "apartment", "accommodation", "room", "suite", "lobby", "reception",
            
            // Lieux touristiques
            "landmark", "monument", "castle", "palace", "temple", "church", "cathedral",
            "museum", "gallery", "theater", "opera", "stadium", "arena", "park",
            "beach", "island", "mountain", "volcano", "canyon", "desert", "forest",
            "lake", "river", "waterfall", "glacier", "cave",
            
            // Activités voyage
            "tourism", "sightseeing", "tour", "guide", "map", "compass", "binoculars",
            "camera", "luggage", "suitcase", "backpack", "passport", "ticket",
            "souvenir", "postcard", "vacation", "holiday", "trip", "journey",
            
            // Villes et pays
            "city", "town", "village", "capital", "downtown", "suburb", "countryside",
            "skyline", "street", "avenue", "square", "plaza"
        ]
        
        return travelKeywords.contains { keyword in
            // Correspondance exacte ou avec séparateurs
            label == keyword || 
            label.hasPrefix(keyword + " ") || 
            label.hasSuffix(" " + keyword) || 
            label.contains(" " + keyword + " ")
        }
    }
    
    private func isNatureLabel(_ label: String) -> Bool {
        let natureKeywords = [
            // Animaux
            "animal", "mammal", "bird", "fish", "reptile", "amphibian", "insect", "spider",
            "cat", "dog", "horse", "cow", "pig", "sheep", "goat", "rabbit", "deer",
            "bear", "wolf", "fox", "lion", "tiger", "elephant", "giraffe", "zebra",
            "monkey", "ape", "gorilla", "chimpanzee", "orangutan", "kangaroo", "koala",
            "panda", "penguin", "dolphin", "whale", "shark", "turtle", "snake", "lizard",
            "frog", "toad", "butterfly", "bee", "ant", "beetle", "dragonfly", "moth",
            
            // Plantes et arbres
            "plant", "tree", "flower", "grass", "leaf", "branch", "root", "stem",
            "oak", "pine", "maple", "palm", "bamboo", "cactus", "fern", "moss",
            "rose", "tulip", "daisy", "sunflower", "lily", "orchid", "carnation",
            
            // Environnement naturel
            "nature", "wilderness", "forest", "jungle", "woods", "meadow", "field",
            "mountain", "hill", "valley", "canyon", "cliff", "rock", "stone",
            "beach", "shore", "ocean", "sea", "lake", "river", "stream", "waterfall",
            "desert", "oasis", "glacier", "iceberg", "volcano", "geyser", "cave", "outdoor",
            
            // Météo et ciel
            "sky", "cloud", "sun", "moon", "star", "rainbow", "lightning", "storm",
            "rain", "snow", "wind", "fog", "mist", "aurora", "sunset", "sunrise"
        ]
        
        return natureKeywords.contains { keyword in
            // Correspondance exacte ou avec séparateurs
            label == keyword || 
            label.hasPrefix(keyword + " ") || 
            label.hasSuffix(" " + keyword) || 
            label.contains(" " + keyword + " ")
        }
    }
    
    private func isTechLabel(_ label: String) -> Bool {
        let techKeywords = [
            // Informatique
            "computer", "laptop", "desktop", "monitor", "screen", "keyboard", "mouse",
            "tablet", "smartphone", "phone", "mobile", "device", "gadget",
            "processor", "cpu", "gpu", "memory", "ram", "storage", "hard_drive",
            "ssd", "usb", "cable", "connector", "port", "adapter",
            
            // Électronique
            "electronics", "circuit", "board", "chip", "semiconductor", "transistor",
            "battery", "charger", "power", "voltage", "current", "wire", "cord",
            "speaker", "headphones", "microphone", "camera", "lens", "sensor",
            
            // Appareils
            "television", "tv", "radio", "stereo", "amplifier", "receiver",
            "projector", "printer", "scanner", "copier", "fax", "modem", "router",
            "switch", "hub", "server", "workstation",
            
            // Logiciels et programmation
            "software", "program", "application", "app", "code", "programming",
            "algorithm", "database", "network", "internet", "web", "website",
            "email", "message", "chat", "video_call", "streaming",
            
            // Innovation et futur
            "robot", "drone", "ai", "artificial_intelligence", "automation",
            "smart", "digital", "virtual", "augmented", "3d_printing"
        ]
        
        return techKeywords.contains { keyword in
            // Correspondance exacte ou avec séparateurs
            label == keyword || 
            label.hasPrefix(keyword + " ") || 
            label.hasSuffix(" " + keyword) || 
            label.contains(" " + keyword + " ")
        }
    }
    
    private func isArtLabel(_ label: String) -> Bool {
        let artKeywords = [
            // Arts visuels
            "art", "painting", "drawing", "sketch", "illustration", "artwork", "canvas",
            "brush", "paint", "palette", "easel", "frame", "gallery", "museum",
            "sculpture", "statue", "figurine", "pottery", "ceramic", "clay",
            
            // Musique
            "music", "musical", "instrument", "piano", "guitar", "violin", "drums",
            "trumpet", "saxophone", "flute", "clarinet", "harp", "organ", "accordion",
            "concert", "orchestra", "band", "singer", "musician", "composer",
            "song", "melody", "rhythm", "harmony", "note", "chord",
            
            // Spectacle
            "theater", "theatre", "stage", "performance", "actor", "actress",
            "drama", "comedy", "play", "musical", "opera", "ballet", "dance",
            "dancer", "choreography", "costume", "makeup", "mask",
            
            // Arts décoratifs
            "craft", "handmade", "artisan", "pottery", "weaving", "embroidery",
            "jewelry", "design", "pattern", "decoration", "ornament",
            
            // Photographie et cinéma
            "photography", "photo", "camera", "lens", "film", "movie", "cinema",
            "director", "producer", "actor", "scene", "shot", "editing"
        ]
        
        return artKeywords.contains { keyword in
            // Correspondance exacte ou avec séparateurs
            label == keyword || 
            label.hasPrefix(keyword + " ") || 
            label.hasSuffix(" " + keyword) || 
            label.contains(" " + keyword + " ")
        }
    }
    
    private func isSportsLabel(_ label: String) -> Bool {
        let sportsKeywords = [
            // Sports généraux
            "sport", "athletics", "exercise", "fitness", "workout", "training",
            "gym", "gymnasium", "stadium", "arena", "field", "court", "track",
            "athlete", "player", "team", "coach", "referee", "competition",
            "tournament", "championship", "league", "match", "game",
            
            // Sports de balle
            "football", "soccer", "basketball", "baseball", "tennis", "volleyball",
            "golf", "ping_pong", "badminton", "squash", "cricket", "rugby",
            "bowling", "billiards", "pool", "snooker",
            
            // Sports aquatiques
            "swimming", "diving", "surfing", "sailing", "rowing", "kayaking",
            "canoeing", "water_polo", "synchronized_swimming", "scuba_diving",
            
            // Sports d'hiver
            "skiing", "snowboarding", "ice_skating", "hockey", "figure_skating",
            "bobsled", "luge", "curling", "biathlon",
            
            // Sports de combat
            "boxing", "wrestling", "martial_arts", "karate", "judo", "taekwondo",
            "fencing", "kickboxing", "mma",
            
            // Sports extrêmes
            "skateboarding", "snowboarding", "surfing", "rock_climbing", "bungee",
            "skydiving", "paragliding", "motocross", "bmx",
            
            // Équipements sportifs
            "ball", "bat", "racket", "club", "stick", "helmet", "uniform",
            "jersey", "cleats", "glove", "pad", "goal", "net", "hoop"
        ]
        
        return sportsKeywords.contains { keyword in
            // Correspondance exacte ou avec séparateurs
            label == keyword || 
            label.hasPrefix(keyword + " ") || 
            label.hasSuffix(" " + keyword) || 
            label.contains(" " + keyword + " ")
        }
    }
    
    private func isCarsLabel(_ label: String) -> Bool {
        let carsKeywords = [
            // Véhicules
            "car", "automobile", "vehicle", "machine", "sedan", "coupe", "hatchback", "wagon",
            "suv", "truck", "van", "minivan", "pickup", "convertible", "limousine",
            "sports_car", "race_car", "formula_one", "nascar", "rally",
            
            // Motos et véhicules à deux roues
            "motorcycle", "motorbike", "scooter", "moped", "bicycle", "bike",
            "atv", "quad", "dirt_bike", "chopper", "cruiser",
            
            // Véhicules commerciaux
            "bus", "coach", "taxi", "ambulance", "fire_truck", "police_car",
            "delivery_truck", "semi_truck", "trailer", "tractor", "bulldozer",
            "excavator", "crane", "forklift", "dump_truck",
            
            // Parties de véhicules
            "engine", "motor", "transmission", "brake", "tire", "wheel", "rim",
            "bumper", "hood", "trunk", "door", "window", "mirror", "headlight",
            "taillight", "windshield", "dashboard", "steering_wheel", "seat",
            
            // Transport et circulation
            "traffic", "road", "highway", "street", "intersection", "parking",
            "garage", "gas_station", "mechanic", "repair", "maintenance",
            "license_plate", "registration", "insurance"
        ]
        
        return carsKeywords.contains { keyword in
            // Correspondance exacte ou avec séparateurs
            label == keyword || 
            label.hasPrefix(keyword + " ") || 
            label.hasSuffix(" " + keyword) || 
            label.contains(" " + keyword + " ")
        }
    }
    
    private func isBeautyLabel(_ label: String) -> Bool {
        let beautyKeywords = [
            // Cosmétiques
            "makeup", "cosmetic", "lipstick", "mascara", "eyeliner", "eyeshadow",
            "foundation", "concealer", "blush", "powder", "bronzer", "highlighter",
            "nail_polish", "perfume", "fragrance", "cologne",
            
            // Soins de la peau
            "skincare", "moisturizer", "cleanser", "toner", "serum", "cream",
            "lotion", "sunscreen", "mask", "exfoliant", "anti_aging",
            
            // Soins des cheveux
            "hair", "shampoo", "conditioner", "styling", "gel", "mousse", "spray",
            "dye", "color", "highlights", "perm", "straightening", "curling",
            
            // Outils beauté
            "brush", "applicator", "sponge", "mirror", "tweezers", "scissors",
            "hair_dryer", "curling_iron", "straightener", "razor", "trimmer",
            
            // Spa et bien-être
            "spa", "massage", "facial", "manicure", "pedicure", "waxing",
            "relaxation", "wellness", "beauty_salon", "barber_shop"
        ]
        
        return beautyKeywords.contains { keyword in
            // Correspondance exacte ou avec séparateurs
            label == keyword || 
            label.hasPrefix(keyword + " ") || 
            label.hasSuffix(" " + keyword) || 
            label.contains(" " + keyword + " ")
        }
    }
    
    private func isMediaLabel(_ label: String) -> Bool {
        let mediaKeywords = [
            // Médias traditionnels
            "book", "magazine", "newspaper", "journal", "publication", "print",
            "text", "writing", "reading", "library", "bookstore", "author",
            "writer", "journalist", "editor", "publisher",
            
            // Médias numériques
            "television", "tv", "radio", "podcast", "streaming", "video",
            "audio", "recording", "broadcast", "channel", "program", "show",
            "series", "episode", "documentary", "news", "report",
            
            // Jeux et divertissement
            "game", "video_game", "console", "controller", "arcade", "puzzle",
            "board_game", "card_game", "chess", "checkers", "domino", "dice",
            
            // Communication
            "phone", "telephone", "mobile", "smartphone", "tablet", "computer",
            "internet", "social_media", "email", "message", "chat", "video_call",
            
            // Création de contenu
            "camera", "microphone", "recording", "editing", "production",
            "studio", "broadcast", "livestream", "content", "media"
        ]
        
        return mediaKeywords.contains { keyword in
            // Correspondance exacte ou avec séparateurs
            label == keyword || 
            label.hasPrefix(keyword + " ") || 
            label.hasSuffix(" " + keyword) || 
            label.contains(" " + keyword + " ")
        }
    }
    
    private func isKidsLabel(_ label: String) -> Bool {
        let kidsKeywords = [
            // Enfants et bébés
            "baby", "child", "kid", "toddler", "infant", "newborn", "teen",
            "teenager", "youth", "student", "pupil",
            
            // Jouets
            "toy", "doll", "teddy_bear", "stuffed_animal", "action_figure",
            "puzzle", "blocks", "lego", "board_game", "card_game",
            "ball", "balloon", "kite", "yo_yo", "spinning_top",
            
            // Jeux et activités
            "playground", "swing", "slide", "seesaw", "sandbox", "jungle_gym",
            "trampoline", "hopscotch", "hide_and_seek", "tag", "games",
            
            // Éducation
            "school", "classroom", "teacher", "student", "homework", "book",
            "pencil", "crayon", "marker", "paper", "notebook", "backpack",
            "lunch_box", "uniform", "graduation",
            
            // Bébé et puériculture
            "diaper", "bottle", "pacifier", "crib", "stroller", "car_seat",
            "high_chair", "bib", "rattle", "mobile", "baby_food",
            
            // Fêtes et célébrations enfants
            "birthday", "party", "cake", "candles", "presents", "balloons",
            "clown", "magician", "puppet", "costume", "dress_up"
        ]
        
        return kidsKeywords.contains { keyword in
            // Correspondance exacte ou avec séparateurs
            label == keyword || 
            label.hasPrefix(keyword + " ") || 
            label.hasSuffix(" " + keyword) || 
            label.contains(" " + keyword + " ")
        }
    }
}
