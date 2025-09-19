//
//  VisionLabelMapper.swift
//  PinpinShareExtension
//
//  Mapper intelligent des 1393 labels Vision vers les nouvelles catégories
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
        if isHomeLabel(normalizedLabel) { return "home" }
        if isFashionLabel(normalizedLabel) { return "fashion" }
        if isFoodLabel(normalizedLabel) { return "food" }
        if isTechLabel(normalizedLabel) { return "tech" }
        if isBeautyLabel(normalizedLabel) { return "beauty" }
        if isBooksLabel(normalizedLabel) { return "books" }
        if isMusicLabel(normalizedLabel) { return "music" }
        if isShowLabel(normalizedLabel) { return "show" }
        if isSportsLabel(normalizedLabel) { return "sports" }
        if isOutdoorLabel(normalizedLabel) { return "outdoor" }
        if isAnimalsLabel(normalizedLabel) { return "animals" }
        if isCarsLabel(normalizedLabel) { return "cars" }
        if isArtLabel(normalizedLabel) { return "art" }
        
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
            "structure", "wood_processed", "liquid", "water", "water_body",
            "material", "container", "object", "item", "thing", "stuff", "conveyance",
            "housewares", "office_supplies", "tool", "equipment", "device",
            "people", "person", "human", "crowd", "wood_natural", "raw_glass", "textile", "adult",
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
            "clothing", "jacket", "jeans", "suit", "dress", "skirt", "hoodie", "coat", "tuxedo", "gown", "robe", "uniform", "apron",
            "bathrobe", "kimono", "sari", "kilt", "poncho", "cloak", "leotard", "costume", "wedding_dress",
            "bib", "military_uniform", "lab_coat", "safety_vest", "wetsuit", "swimsuit",
            
            // Chaussures
            "shoes", "boot", "sneaker", "sandal", "high_heel", "loafer", "moccasin", "flipper",
            "ski_boot", "ice_skates", "rollerskates",
            
            // Accessoires
            "hat", "beanie", "fedora", "cowboy_hat", "sunhat", "sombrero", "tiara", "helmet",
            "baseball_hat", "hardhat", "headgear",
            "bag", "purse", "backpack", "briefcase", "suitcase", "luggage", "wallet",
            "jewelry", "watch", "bowtie", "necktie", "scarf", "glove", "mitten", "sock", "earmuffs",
            "glove_other", "footwear",
            "sunglasses", "eyeglasses", "goggles", "mask", "gas_mask",
            
            // Mariages et événements
            "bride", "bridesmaid", "groom"
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
            "armchair", "bench", "stool", "wardrobe", "closet",
            "folding_chair", "swivel_chair", "high_chair", "chaise", "chair_other",
            
            // Pièces
            "room", "bedroom", "living_room", "kitchen", "bathroom", "office",
            "garage", "balcony", "porch", "patio", "deck", "cellar",
            "kitchen_room", "bathroom_room", "interior_room",
            
            // Électroménager
            "appliance", "refrigerator", "oven", "microwave", "dishwasher", "washing_machine",
            "dryer", "vacuum", "blender", "toaster", "kettle", "juicer",
            "toaster_oven", "kitchen_oven", "electric_fan", "laundry_machine", "iron_clothing",
            
            // Décoration
            "lamp", "light", "chandelier", "candle", "candlestick", "mirror", "frame",
            "vase", "plant", "flower", "bouquet", "decoration", "ornament", "wreath",
            "curtain", "pillow", "blanket", "decorative_plant",
            "christmas_decoration", "christmas_tree", "light_bulb", "decoration",
            
            // Salle de bain
            "bath", "shower", "bathroom_faucet", "kitchen_faucet", "kitchen_sink", "washbasin", "toilet_seat",
            
            // Maison générale
            "house", "home", "apartment", "building", "door", "window", "roof", "chimney",
            "stairs", "elevator", "escalator", "floor", "ceiling", "wall", "house_single",
            "domicile", "kitchen_countertop", "fireplace", "mailbox", "manhole",
            "dining_room", "interior_shop",
            
            // Rangement et nettoyage
            "basket_container", "bedding", "broom", "bucket", "cardboard_box", "clothesline", "clothespin",
            "crate", "flashlight", "hammock", "mop", "mousetrap", "paper_bag", "pole", "pool",
            "sack", "shed", "stove", "trash_can", "umbrella", "watering_can", "wheelbarrow",
            "carton", "sprinkler",
            
            // Sécurité et éclairage
            "extinguisher", "lamppost",
            
            // Décoration florale
            "flower_arrangement"
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
            "food", "baked_goods",
            
            // Fruits
            "fruit", "apple", "banana", "orange", "grape", "strawberry", "blueberry", "raspberry",
            "cherry", "peach", "pear", "plum", "apricot", "kiwi", "mango", "pineapple",
            "watermelon", "melon", "cantaloupe", "honeydew", "lemon", "lime", "grapefruit",
            "avocado", "coconut", "papaya", "guava", "passionfruit", "lychee", "rambutan",
            "durian", "persimmon", "pomegranate", "fig", "berry", "citrus_fruit",
            "blackberry", "cranberry", "mandarine", "nectarine", "starfruit", "mangosteen",
            
            // Légumes
            "vegetable", "carrot", "broccoli", "spinach", "lettuce", "tomato", "cucumber",
            "pepper", "bell_pepper", "pepper_veggie", "onion", "garlic", "potato", "corn", "pea", "bean", "celery",
            "asparagus", "artichoke", "eggplant", "zucchini", "squash", "pumpkin",
            "beet", "radish", "turnip", "cabbage", "cauliflower",
            "green_beans", "leek", "chives", "cilantro", "dill", "rosemary", "arugula",
            "daikon", "kohlrabi", "edamame", "habanero", "jalapeno", "lemongrass", "turmeric",
            
            // Viandes et protéines
            "meat", "beef", "pork", "chicken", "turkey", "duck", "fish", "salmon",
            "tuna", "lobster", "crab", "oyster", "clam", "mussel", "scallop",
            "egg", "cheese", "milk", "yogurt", "butter", "poultry", "seafood", "ham",
            "bacon", "sausage", "pepperoni", "anchovy", "barracuda", "mackerel", "sardine",
            "seabass", "snapper", "trout", "fried_chicken", "grilled_chicken", "fried_egg",
            "scrambled_eggs", "omelet", "yolk", "meatball", "spareribs", "rotisserie",
            "shellfish", "shellfish_prepared", "roe",
            
            // Plats préparés
            "pizza", "burger", "hamburger", "sandwich", "salad", "soup", "pasta", "spaghetti", "noodles",
            "rice", "bread", "cake", "pie", "cookie", "muffin", "donut", "bagel",
            "pancake", "waffle", "cereal", "oatmeal", "ice_cream", "chocolate",
            "candy", "chewing_gum", "popcorn", "pretzel", "fries", "nachos",
            "hotdog", "taco", "burrito", "quesadilla", "falafel", "hummus", "guacamole",
            "antipasti", "bruschetta", "caprese", "casserole", "coleslaw", "crepe", "croissant",
            "curry", "dumpling", "fondue", "fruitcake", "gingerbread", "gyoza", "kebab",
            "naan", "paella", "pierogi", "pita", "risotto", "samosa", "satay", "sauerkraut",
            "shawarma", "souffle", "souvlaki", "springroll", "stir_fry", "strudel", "sushi",
            "tabbouleh", "tapas", "tempura", "teriyaki", "tiramisu", "tortilla", "wonton",
            "biryani", "biscotti", "biscuit", "brownie", "cheesecake", "chocolate_chip",
            "cupcake", "flan", "frozen_dessert", "jello", "jelly", "marshmallow", "pudding",
            "popsicle", "taffy", "wedding_cake", "birthday_cake", "cake_regular", "dessert",
            "frozen", "white_bread", "matzo", "scone",
            
            // Boissons
            "drink", "water", "juice", "soda", "coffee", "tea", "wine", "beer", "cocktail",
            "smoothie", "milkshake", "tea_drink", "bubble_tea", "liquor",
            "margarita", "martini", "mojito", "sangria", "tequila", "red_wine", "white_wine",
            "sparkling_wine", "liquid",
            
            // Noix et graines
            "nut", "almond", "cashew", "chestnut", "macadamia", "peanut", "pecan", "pistachio",
            "sesame", "sunflower_seeds", "seed",
            
            // Épices et condiments
            "spice", "herb", "sugar", "honey", "sauce",
            "mustard", "vinegar", "oil", "condiment", "seasonings",
            "wasabi", "caramel", "sugar_cube", "grain", "quinoa", "wheat", "rice_field",
            "seaweed", "tapioca_pearls", "taro",
            
            // Ustensiles et vaisselle de cuisine
            "cookware", "pan", "pot", "bowl", "plate", "cup", "mug", "glass", "bottle", "jar",
            "fork", "knife", "spoon", "chopsticks", "cutting_board", "grater", "whisk",
            "ladle", "spatula", "corkscrew", "rolling_pin", "steamer_cookware",
            "tableware", "drinking_glass", "teapot", "cakestand", "decanter", "pot_cooking",
            
            // Spécialités culinaires
            "baklava", "coffee_bean", "keg", "lollipop", "oranges", "pastry", "pickle",
            "ramen", "rhubarb", "salami", "steak", "straw_drinking", "wine_bottle",
            "candy_cane", "candy_other"
        ]
        
        return foodKeywords.contains { keyword in
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
            "computer", "monitor", "screen", "keyboard", "mouse",
            "tablet", "smartphone", "phone", "mobile",
            "cable", "computer_keyboard", "computer_monitor", "computer_mouse", "computer_tower",
            "consumer_electronics", "optical_equipment",
            
            // Électronique
            "electronics", "circuit", "board", "chip", "battery", "charger", "wire", "cord",
            "speaker", "headphones", "microphone", "camera", "lens", "sensor",
            "circuit_board", "speakers_music", "stereo", "turntable",
            
            // Appareils
            "television", "tv", "radio", "projector", "printer", "scanner", "payphone", "atm",
            
            // Outils de mesure et calcul
            "calculator", "caliper", "measuring_tape", "microscope", "telescope",
            "stethoscope", "thermometer", "thermostat", "stopwatch", "timepiece",
            "tachometer", "dial", "gears", "pulley", "ratchet",
            
            // Innovation et futur
            "robot", "drone", "drone_machine", "solar_panel", "wind_turbine", "rocket",
            
            // Outils de calcul et mesure anciens/modernes
            "abacus", "keypad", "laptop", "megaphone", "spotlight", "syringe", "tripod", "typewriter"
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
            "art", "painting", "illustration", "easel", "frame", "gallery", "museum",
            "sculpture", "statue", "figurine", "pottery",
            "illustrations", "paintbrush", "stained_glass", "origami", "tattoo",
            "rangoli", "henna", "graffiti",
            
            // Arts décoratifs
            "craft", "handmade", "artisan", "pottery", "weaving", "embroidery",
            "jewelry", "design", "pattern", "ornament",
            "sewing", "yarn",
            
            // Photographie et cinéma
            "photography", "photo", "camera", "lens", "film", "movie", "cinema",
            "screenshot",
            
            // Objets d'art et artisanat
            "anvil", "barrel", "brick", "brick_oven", "coin", "credit_card", "currency", "flame",
            "hammer", "hourglass", "mallet", "matches", "money", "pipe", "pliers", "podium",
            "polka_dots", "portal", "porthole", "rowboat", "screwdriver", "skeleton", "skull",
            "smoking_item", "straw_hay", "stretcher", "toolbox", "utensil", "winch", "wrench", "axe"
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
            "sport", "athletics", "gymnasium", "stadium", "arena", "field", "games",
            "health_club", "rink", "scoreboard", "trophy", "medal",
            
            // Sports de balle
            "football", "soccer", "basketball", "baseball", "tennis", "volleyball",
            "golf", "ping_pong", "badminton", "squash", "cricket", "rugby",
            "bowling", "billiards", "softball", "ballgames",
            "golf_ball", "golf_club", "golf_course", "putt", "puck",
            
            // Sports aquatiques
            "swimming", "diving", "surfing", "sailing", "rowing", "kayaking",
            "canoeing", "water_polo", "scuba", "snorkeling", "waterpolo", "watersport", "wakeboarding",
            "windsurfing", "kiteboarding", "parasailing", "rafting",
            
            // Sports d'hiver
            "skiing", "snowboarding", "ice_skating", "hockey", "skating", "winter_sport",
            "ski_equipment", "snowboard", "snowmobile", "snowshoe", "sledding",
            
            // Sports de combat
            "boxing", "wrestling", "martial_arts", "fencing_sport", "sumo",
            
            // Sports extrêmes
            "skateboarding", "rock_climbing", "bungee",
            "skydiving", "motocross", "skatepark",
            "hangglider",
            
            // Cyclisme et vélos
            "cycling", "bicycle", "tricycle",
            
            // Sports équestres
            "equestrian", "dressage", "jockey_horse", "horseshoe", "rodeo",
            
            // Autres sports
            "archery", "dartboard", "gymnastics", "cheerleading", "polo",
            "hurdle", "hunting", "fishing", "hiking", "yoga", "treadmill",
            "dumbbell", "barbell", "weight_scale",
            
            // Équipements sportifs
            "ball", "bat", "racket", "club", "stick", "helmet", "uniform",
            "glove", "net", "hoop", "racquet", "sports_equipment", "baseball_bat", "lifejacket",
            "lifesaver", "flipper", "surfboard", "bodyboard", "frisbee",
            
            // Installations sportives
            "bleachers",
            
            // Sports spécifiques
            "squash_sport"
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
            "car", "automobile", "vehicle", "machine", "suv", "truck", "van", "convertible", "limousine",
            "formula_one", "sportscar", "formula_one_car", "grand_prix", "go_kart", "jeep", "motorhome",
            
            // Motos et véhicules à deux roues
            "motorcycle", "scooter", "bicycle", "atv", "jetski",
            
            // Véhicules commerciaux et spécialisés
            "bus", "taxi", "ambulance", "police_car", "semi_truck", "tractor", "bulldozer",
            "excavator", "crane", "forklift", "firetruck",
            "backhoe", "crane_construction", "mower", "chainsaw", "power_saw",
            
            // Parties de véhicules
            "engine", "tire", "wheel", "rim", "dashboard", "engine_vehicle", "propeller", "car_seat",
            
            // Transport et circulation
            "traffic", "road", "highway", "street", "parking", "garage", "license_plate",
            "traffic_light", "parking_lot", "hydrant", "road_safety_equipment",
            
            // Motorsport
            "motorsport", "motocross",
            
            // Transport spécialisé
            "cart", "parachute", "saddle"
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
            // Outils beauté (seuls labels présents dans Vision)
            "cosmetic_tool", "hair", "brush", "mirror", "scissors", "razor", "spa", "jacuzzi",
            
            // Accessoires bien-être
            "hookah",
            
            // Objets personnels de santé
            "crutch", "medicine"
        ]
        
        return beautyKeywords.contains { keyword in
            // Correspondance exacte ou avec séparateurs
            label == keyword || 
            label.hasPrefix(keyword + " ") || 
            label.hasSuffix(" " + keyword) || 
            label.contains(" " + keyword + " ")
        }
    }
    
    private func isOutdoorLabel(_ label: String) -> Bool {
        let outdoorKeywords = [
            // Transport
            "airplane", "aircraft", "helicopter",
            "train", "station", "bus", "taxi",
            "ship", "boat", "yacht", "sailboat", "speedboat",
            "car", "highway", "road", "bridge", "tunnel", "airport", "airshow",
            "train_real", "train_station", "cruise_ship", "barge", "houseboat", "warship",
            "rickshaw", "streetcar", "tramway", "monorail", "cableway", "chairlift",
            
            // Lieux touristiques
            "landmark", "monument", "castle", "palace", "temple", "church", "cathedral",
            "museum", "gallery", "theater", "opera", "stadium", "arena", "park",
            "beach", "island", "mountain", "volcano", "canyon", "desert", "forest",
            "lake", "river", "waterfall", "glacier", "cave", "shore", "harbour",
            "lighthouse", "pier", "dock", "belltower", "clock_tower", "tower",
            "ruins", "megalith", "obelisk", "pyramid", "statue", "gargoyle",
            
            // Activités voyage
            "map", "compass", "binoculars",
            "camera", "luggage", "suitcase", "backpack", "passport", "ticket",
            
            // Villes et pays
            "city", "town", "village", "skyline", "street", "square", "plaza", "cityscape", "alley",
            "crosswalk", "sidewalk", "driveway", "path", "trail", "dirt_road", "road_other",
            
            // Environnement naturel
            "nature", "wilderness", "forest", "jungle", "field",
            "mountain", "hill", "canyon", "cliff", "rock", "stone", "rocks",
            "beach", "shore", "ocean", "sea", "lake", "river", "waterfall",
            "desert", "glacier", "iceberg", "volcano", "geyser", "cave", "outdoor",
            "land", "orchard", "vineyard", "wetland", "sand", "sand_dune", "creek",
            "waterways", "water_body", "underwater", "lava", "embers",
            
            // Météo et ciel
            "sky", "cloud", "sun", "moon", "star", "rainbow", "lightning", "storm",
            "snow", "aurora", "blue_sky", "night_sky", "celestial_body", "celestial_body_other",
            "cloudy", "daytime", "haze", "blizzard", "thunderstorm", "tornado",
            "sunset_sunrise", "ice", "iceberg", "snowball", "snowman",
            
            // Agriculture et structures extérieures
            "agriculture", "balloon_hotair", "boathouse", "camping", "farm", "fence", "fountain",
            "garden", "gazebo", "grave", "greenhouse", "hangar", "hospital", "igloo", "library",
            "pergola", "pylon", "railroad", "restaurant", "sandcastle", "shipyard", "shopping_cart",
            "silo", "skyscraper", "smokestack", "storefront", "street_sign", "submarine_water",
            "sunbathing", "sundial", "tent", "track_rail", "wagon", "watercraft", "watermill",
            "wheelchair", "windmill", "zoo"
        ]
        
        return outdoorKeywords.contains { keyword in
            // Correspondance exacte ou avec séparateurs
            label == keyword || 
            label.hasPrefix(keyword + " ") || 
            label.hasSuffix(" " + keyword) || 
            label.contains(" " + keyword + " ")
        }
    }
    
    private func isAnimalsLabel(_ label: String) -> Bool {
        let animalsKeywords = [
            // Animaux domestiques
            "animal", "mammal", "bird", "fish", "reptile", "insect", "spider",
            "cat", "dog", "horse", "cow", "pig", "sheep", "goat", "rabbit", "deer",
            "adult_cat", "kitten", "canine", "feline", "poultry",
            
            // Races de chiens
            "australian_shepherd", "basenji", "basset", "beagle", "bernese_mountain", "bichon",
            "bulldog", "chihuahua", "collie", "corgi", "dachshund", "dalmatian", "doberman",
            "german_shepherd", "golden_retriever", "greyhound", "husky", "irish_wolfhound",
            "jack_russell_terrier", "malamute", "malinois", "mastiff", "newfoundland",
            "pitbull", "pomeranian", "poodle", "pug", "retriever", "rottweiler",
            "saint_bernard", "schnauzer", "setter", "sheepdog", "spaniel", "terrier",
            "vizsla", "weimaraner", "hound",
            
            // Animaux sauvages
            "bear", "wolf", "fox", "lion", "tiger", "elephant", "giraffe", "zebra",
            "monkey", "gorilla", "kangaroo", "koala",
            "panda", "penguin", "dolphin", "whale", "shark", "turtle", "snake", "lizard",
            "frog", "toad", "butterfly", "bee", "ant", "dragonfly", "moth",
            "alligator_crocodile", "bison", "boar", "bobcat", "camel", "caterpillar",
            "centipede", "chameleon", "cheetah", "chinchilla", "cougar", "coyote_wolf",
            "donkey", "eagle", "elk", "ferret", "flamingo", "gecko", "gerbil",
            "hamster", "hedgehog", "heron", "hippopotamus", "hyena", "iguana",
            "lemur", "leopard", "llama", "lynx", "moose", "ostrich", "otter",
            "owl", "parakeet", "parrot", "peacock", "pelican", "peregrine", "pigeon",
            "porcupine", "prairie_dog", "puffin", "python", "raccoon", "rat",
            "rattlesnake", "raven", "rhinoceros", "scorpion", "seal", "sealion",
            "skunk", "snake_other", "sparrow", "squirrel", "stork", "swan",
            "tortoise", "toucan", "vulture", "walrus", "woodpecker",
            
            // Animaux marins
            "cetacean", "cephalopod", "gastropod", "mollusk", "angelfish", "clownfish",
            "goldfish", "guppy", "koi", "lionfish", "puffer_fish", "seahorse",
            "starfish", "stingray", "sunfish", "swordfish", "barnacle", "conch",
            "crab", "jellyfish", "seashell", "urchin", "coral_reef",
            
            // Arthropodes et autres
            "arachnid", "arthropods", "ladybug", "millipede", "scarab", "snail",
            "spider", "spiderweb", "worm", "ant", "cockroach", "cricket_sport",
            
            // Plantes et arbres (restent dans animals car liés à la nature vivante)
            "plant", "tree", "flower", "grass", "leaf", "branch", "cactus", "fern", "moss",
            "rose", "tulip", "daisy", "sunflower", "lily", "orchid", "carnation",
            "oak_tree", "palm_tree", "maple_tree", "eucalyptus_tree", "evergreen",
            "sequoia", "willow", "bonsai", "ivy", "mangrove", "vegetation", "foliage",
            "blossom", "clover", "dandelion", "holly", "mistletoe", "poinsettia",
            "begonia", "chrysanthemum", "cornflower", "daffodil", "dahlia",
            "marigold", "petunia", "snapdragon", "ferns", "shrub", "acorn", "mushroom",
            
            // Habitats et accessoires animaux
            "aquarium", "beehive", "beekeeping", "birdhouse", "cage", "fishbowl", "fishtank",
            "leash", "nest", "scarecrow", "terrarium",
            
            // Animaux spécifiques supplémentaires
            "cockatoo", "dinosaur", "dove", "gull", "hummingbird", "marsupial", "monitor_lizard",
            "raptor", "ridgeback", "rodent", "sandpiper", "ungulates"
        ]
        
        return animalsKeywords.contains { keyword in
            // Correspondance exacte ou avec séparateurs
            label == keyword || 
            label.hasPrefix(keyword + " ") || 
            label.hasSuffix(" " + keyword) || 
            label.contains(" " + keyword + " ")
        }
    }
    
    private func isBooksLabel(_ label: String) -> Bool {
        let booksKeywords = [
            // Livres et lecture
            "book", "magazine", "newspaper", "printed_page",
            "document", "handwriting", "envelope", "receipt", "coupon",
            "checkbook", "sticky_note", "calendar", "map", "chart", "diagram",
            
            // Signalisation et affichage
            "banner", "billboards", "flag", "flagpole"
        ]
        
        return booksKeywords.contains { keyword in
            // Correspondance exacte ou avec séparateurs
            label == keyword || 
            label.hasPrefix(keyword + " ") || 
            label.hasSuffix(" " + keyword) || 
            label.contains(" " + keyword + " ")
        }
    }
    
    private func isMusicLabel(_ label: String) -> Bool {
        let musicKeywords = [
            // Musique et instruments
            "music", "musical", "instrument", "piano", "guitar", "violin", "drums",
            "trumpet", "saxophone", "flute", "clarinet", "harp", "organ", "accordion",
            "concert", "orchestra", "band", "singer", "musician",
            "musical_instrument", "cello", "trombone", "tuba", "ukulele", "xylophone",
            "tambourine", "bongo_drum", "brass_music", "string_instrument", "woodwind",
            "organ_instrument", "karaoke", "deejay", "record", "cassette", "cd",
            
            // Équipement audio
            "radio", "speakers_music", "stereo", "turntable", "diskette",
            
            // Ambiance musicale
            "disco_ball"
        ]
        
        return musicKeywords.contains { keyword in
            // Correspondance exacte ou avec séparateurs
            label == keyword || 
            label.hasPrefix(keyword + " ") || 
            label.hasSuffix(" " + keyword) || 
            label.contains(" " + keyword + " ")
        }
    }
    
    private func isShowLabel(_ label: String) -> Bool {
        let showKeywords = [
            // Spectacle et divertissement
            "theater", "theatre", "stage", "performance", "actor", "actress",
            "drama", "comedy", "play", "musical", "opera", "ballet", "dance",
            "dancer", "choreography", "costume", "makeup", "mask",
            "dancing", "ballet_dancer", "bellydance", "breakdancing", "samba",
            "hula", "entertainer", "clown", "magician", "puppet", "circus",
            "juggling", "acrobat", "performance",
            
            // Médias audiovisuels
            "television", "tv", "video", "media",
            
            // Jeux et divertissement
            "game", "puzzle", "board_game", "chess", "domino", "dice",
            "videogame", "gamepad", "joystick", "games", "puzzles", "jigsaw",
            "backgammon", "foosball", "poker", "roulette", "casino", "play_card",
            
            // Spectacles et événements
            "bullfighting", "diorama", "fireworks", "kickboxing", "nascar", "nightclub", "paintball",
            "pyrotechnics", "recreation", "rollerskating", "sparkler", "workout",
            
            // Objets de fête et célébration
            "firecracker",
            
            // Accessoires fumeurs
            "cigar", "cigarette", "lighter"
        ]
        
        return showKeywords.contains { keyword in
            // Correspondance exacte ou avec séparateurs
            label == keyword || 
            label.hasPrefix(keyword + " ") || 
            label.hasSuffix(" " + keyword) || 
            label.contains(" " + keyword + " ")
        }
    }
}
