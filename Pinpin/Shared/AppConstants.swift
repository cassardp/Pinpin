//
//  AppConstants.swift
//  Pinpin
//
//  Constantes partagées entre l'app et l'extension
//

import Foundation
import CoreGraphics

enum AppConstants {
    // MARK: - App Group
    static let groupID = "group.com.misericode.pinpin"
    
    // MARK: - CloudKit
    static let cloudKitContainerID = "iCloud.com.misericode.Pinpin"
    
    
    // MARK: - Image Optimization
    static let maxImageSize: CGFloat = 1024
    static let maxImageBytes = 1_000_000
    static let defaultCompressionQuality: CGFloat = 0.8
    static let minimumCompressionQuality: CGFloat = 0.1
    
    // MARK: - Pagination
    static let itemsPerPage = 10
    
    // MARK: - Category Names
    static let miscCategoryNames = ["Misc"]
    static let defaultCategoryName = "Misc"
    
    // MARK: - User Defaults Keys
    static let numberOfColumnsKey = "numberOfColumns"
    static let hasCreatedDefaultCategoriesKey = "hasCreatedDefaultCategories"
    
    // MARK: - Layout
    // MARK: - Layout
    #if os(macOS)
    static let minColumns = 3
    static let maxColumns = 6
    static let defaultColumns = 4
    #else
    static let minColumns = 2
    static let maxColumns = 4
    static let defaultColumns = 3
    #endif
    
    // MARK: - Dynamic Spacing
    static func spacing(for columns: Int) -> CGFloat {
        switch columns {
        case 1: return 12
        case 2: return 12
        case 3: return 10
        case 4: return 8
        case 5: return 8
        case 6: return 6
        default: return 8
        }
    }
    
    static func cornerRadius(for columns: Int, disabled: Bool = false) -> CGFloat {
        if disabled { return 0 }
        switch columns {
        case 1: return 18
        case 2: return 14
        case 3: return 12
        case 4: return 10
        case 5: return 8
        case 6: return 6
        default: return 10
        }
    }
    
    // MARK: - Default Categories
    static let defaultCategories: [String] = [
        "Home",
        "Clothes",
        "Food",
        "Tech",
        "Ideas",
        "Outdoor",
        "Music",
        "Books",
        "Cars"
    ]
}
