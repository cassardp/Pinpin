//
//  AppConstants.swift
//  Pinpin
//
//  Constantes partagées entre l'app et l'extension
//

import Foundation
import CoreGraphics
import SwiftUI

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
    static let minColumns = 4
    static let maxColumns = 6
    static let defaultColumns = 5
    #else
    static let minColumns = 2
    static let maxColumns = 4
    static let defaultColumns = 3
    #endif
    
    // MARK: - Dynamic Spacing
    // MARK: - Dynamic Spacing
    static func spacing(for columns: Int) -> CGFloat {
        #if os(iOS)
        switch columns {
        case 1, 2: return 12
        case 3: return 10
        case 4: return 8
        default: return 8
        }
        #else
        switch columns {
        case 4: return 10
        case 5: return 8
        case 6: return 6
        default: return 10
        }
        #endif
    }
    
    static func cornerRadius(for columns: Int, disabled: Bool = false) -> CGFloat {
        if disabled { return 0 }
        #if os(iOS)
        switch columns {
        case 1: return 18
        case 2: return 14
        case 3: return 12
        case 4: return 10
        default: return 14
        }
        #else
        switch columns {
        case 4: return 10
        case 5: return 8
        case 6: return 6
        default: return 10
        }
        #endif
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
    
    // MARK: - Adaptive Content Properties
    
    static func contentTitleFont(for columns: Int) -> Font {
        #if os(iOS)
        switch columns {
        case 2: return .system(size: 17)
        case 3: return .system(size: 14)
        case 4: return .system(size: 12)
        default: return .system(size: 17)
        }
        #else
        switch columns {
        case 4: return .system(size: 15)
        case 5: return .system(size: 14)
        case 6: return .system(size: 13)
        default: return .system(size: 15)
        }
        #endif
    }
    
    static func contentDescriptionFont(for columns: Int) -> Font {
        #if os(iOS)
        switch columns {
        case 2: return .system(size: 13)
        case 3: return .system(size: 11)
        case 4: return .system(size: 10)
        default: return .system(size: 13)
        }
        #else
        switch columns {
        case 4: return .system(size: 12)
        case 5: return .system(size: 11)
        case 6: return .system(size: 11)
        default: return .system(size: 12)
        }
        #endif
    }
    
    static func contentTitleLineLimit(for columns: Int) -> Int {
        #if os(iOS)
        switch columns {
        case 2: return 8
        case 3: return 6
        case 4: return 4
        default: return 8
        }
        #else
        switch columns {
        case 4: return 8
        case 5: return 6
        case 6: return 5
        default: return 8
        }
        #endif
    }
    
    static func contentDescriptionLineLimit(for columns: Int) -> Int {
        #if os(iOS)
        switch columns {
        case 2: return 8
        case 3: return 6
        case 4: return 4
        default: return 8
        }
        #else
        switch columns {
        case 4: return 8
        case 5: return 6
        case 6: return 5
        default: return 8
        }
        #endif
    }
    
    static func contentSpacing(for columns: Int) -> CGFloat {
        #if os(iOS)
        switch columns {
        case 2: return 8
        case 3: return 4
        case 4: return 4
        default: return 8
        }
        #else
        switch columns {
        case 4: return 10
        case 5: return 8
        case 6: return 6
        default: return 10
        }
        #endif
    }
    
    static func contentPadding(for columns: Int) -> CGFloat {
        #if os(iOS)
        switch columns {
        case 2: return 16
        case 3: return 10
        case 4: return 8
        default: return 16
        }
        #else
        switch columns {
        case 4: return 14
        case 5: return 12
        case 6: return 10
        default: return 14
        }
        #endif
    }
    
    static func contentIconSize(for columns: Int) -> CGFloat {
        #if os(iOS)
        switch columns {
        case 2: return 40
        case 3: return 28
        case 4: return 20
        default: return 40
        }
        #else
        switch columns {
        case 4: return 32
        case 5: return 28
        case 6: return 24
        default: return 32
        }
        #endif
    }
    
    static func contentIconContainerSize(for columns: Int) -> CGFloat {
        #if os(iOS)
        switch columns {
        case 2: return 100
        case 3: return 70
        case 4: return 50
        default: return 100
        }
        #else
        switch columns {
        case 4: return 80
        case 5: return 70
        case 6: return 60
        default: return 80
        }
        #endif
    }
}
