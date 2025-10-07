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
    static let itemsPerPage = 30
    
    // MARK: - Category Names
    static let miscCategoryNames = ["Misc"]
    static let defaultCategoryName = "Misc"
    
    // MARK: - User Defaults Keys
    static let numberOfColumnsKey = "numberOfColumns"
    static let hasCreatedDefaultCategoriesKey = "hasCreatedDefaultCategories"
    
    // MARK: - Layout
    static let minColumns = 2
    static let maxColumns = 4
    static let defaultColumns = 3
    
    // MARK: - Dynamic Spacing
    static func spacing(for columns: Int) -> CGFloat {
        switch columns {
        case 1: return 16
        case 2: return 10
        case 3: return 8
        case 4: return 6
        default: return 10
        }
    }
    
    static func cornerRadius(for columns: Int, disabled: Bool = false) -> CGFloat {
        if disabled { return 0 }
        switch columns {
        case 1: return 20
        case 2: return 14
        case 3: return 10
        case 4: return 8
        default: return 14
        }
    }
    
    // MARK: - Default Categories
    static let defaultCategories: [String] = [
        "Home",
        "Fashion",
        "Food",
        "Tech",
        "Ideas",
        "Outdoor",
        "Music",
        "Books",
        "Car"
    ]
}
