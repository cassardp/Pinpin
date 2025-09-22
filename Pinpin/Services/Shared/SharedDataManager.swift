//
//  SharedDataManager.swift
//  Pinpin
//
//  Gestionnaire de données partagées ultra-simple (UserDefaults + App Group)
//

import Foundation

public class SharedDataManager {
    public static let shared = SharedDataManager()
    
    private let sharedDefaults: UserDefaults
    
    private init() {
        guard let defaults = UserDefaults(suiteName: "group.com.misericode.pinpin") else {
            fatalError("App Group non configuré")
        }
        self.sharedDefaults = defaults
    }
    
    // MARK: - Category Counts
    
    /// Met à jour le compteur d'une catégorie
    public func updateCategoryCount(_ category: String, count: Int) {
        sharedDefaults.set(count, forKey: "count_\(category)")
        sharedDefaults.synchronize()
    }
    
    /// Récupère le compteur d'une catégorie
    public func getCategoryCount(_ category: String) -> Int {
        return sharedDefaults.integer(forKey: "count_\(category)")
    }
    
    /// Met à jour tous les compteurs depuis Core Data (appelé par l'app principale)
    public func refreshAllCategoryCounts(from context: NSManagedObjectContext) {
        let categories = ["home", "fashion", "food", "tech", "beauty", "books", "music", "show", "sports", "outdoor", "animals", "vehicles", "art", "misc"]
        
        for category in categories {
            let request: NSFetchRequest<ContentItem> = ContentItem.fetchRequest()
            request.predicate = NSPredicate(format: "contentType == %@", category)
            
            do {
                let count = try context.count(for: request)
                updateCategoryCount(category, count: count)
            } catch {
                print("Erreur comptage \(category): \(error)")
                updateCategoryCount(category, count: 0)
            }
        }
    }
}
