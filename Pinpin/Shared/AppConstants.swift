//
//  AppConstants.swift
//  Pinpin
//
//  Constantes partagées entre l'app et l'extension
//

import Foundation
import CoreGraphics
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

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

    // MARK: - Device Detection
    #if os(iOS)
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    #else
    static let isIPad = false
    #endif

    // MARK: - Layout
    #if os(macOS)
    static let minColumns = 3
    static let maxColumns = 10
    static let defaultColumns = 6
    static let idealItemWidth: CGFloat = 160
    #else
    // iPhone utilise 2-4 colonnes, iPad utilise les mêmes valeurs que macOS (3-10)
    static var minColumns: Int {
        isIPad ? 3 : 2
    }
    static var maxColumns: Int {
        isIPad ? 10 : 4
    }
    static var defaultColumns: Int {
        isIPad ? 5 : 3
    }
    static var idealItemWidth: CGFloat {
        isIPad ? 160 : 120
    }
    #endif

    // MARK: - iPad Optimal Columns (adapté de macOS)
    #if os(iOS)
    static func optimalColumns(for width: CGFloat, spacing: CGFloat = 16, horizontalPadding: CGFloat = 32) -> Int {
        guard isIPad else { return defaultColumns }
        let availableWidth = width - horizontalPadding
        let columns = Int((availableWidth + spacing) / (idealItemWidth + spacing))
        return max(minColumns, min(maxColumns, columns))
    }
    #endif

    #if os(macOS)
    /// Calcule le nombre optimal de colonnes pour une largeur donnée
    static func optimalColumns(for width: CGFloat, spacing: CGFloat = 16, horizontalPadding: CGFloat = 32) -> Int {
        let availableWidth = width - horizontalPadding
        let columns = Int((availableWidth + spacing) / (idealItemWidth + spacing))
        return max(minColumns, min(maxColumns, columns))
    }
    #endif

    // MARK: - Dynamic Spacing
    static func spacing(for columns: Int) -> CGFloat {
        #if os(iOS)
        if isIPad {
            // iPad utilise les mêmes valeurs que macOS (harmonisées)
            switch columns {
            case 3: return 16
            case 4: return 14
            case 5: return 12
            case 6: return 11
            case 7: return 10
            case 8: return 9
            case 9: return 8
            case 10: return 7
            default: return 12
            }
        } else {
            switch columns {
            case 1, 2: return 12
            case 3: return 10
            case 4: return 8
            default: return 8
            }
        }
        #else
        switch columns {
        case 3: return 16
        case 4: return 14
        case 5: return 12
        case 6: return 11
        case 7: return 10
        case 8: return 9
        case 9: return 8
        case 10: return 7
        default: return 12
        }
        #endif
    }

    static func cornerRadius(for columns: Int, disabled: Bool = false) -> CGFloat {
        if disabled { return 0 }
        #if os(iOS)
        if isIPad {
            switch columns {
            case 3: return 14
            case 4: return 12
            case 5: return 10
            case 6: return 9
            case 7: return 8
            case 8: return 7
            case 9: return 6
            case 10: return 5
            default: return 10
            }
        } else {
            switch columns {
            case 1: return 18
            case 2: return 14
            case 3: return 12
            case 4: return 10
            default: return 14
            }
        }
        #else
        switch columns {
        case 3: return 14
        case 4: return 12
        case 5: return 10
        case 6: return 9
        case 7: return 8
        case 8: return 7
        case 9: return 6
        case 10: return 5
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
        if isIPad {
            switch columns {
            case 3: return .system(size: 17)
            case 4: return .system(size: 15)
            case 5: return .system(size: 14)
            case 6: return .system(size: 13)
            case 7: return .system(size: 12)
            case 8: return .system(size: 11)
            case 9: return .system(size: 11)
            case 10: return .system(size: 10)
            default: return .system(size: 14)
            }
        } else {
            switch columns {
            case 2: return .system(size: 17)
            case 3: return .system(size: 14)
            case 4: return .system(size: 12)
            default: return .system(size: 17)
            }
        }
        #else
        switch columns {
        case 3: return .system(size: 17)
        case 4: return .system(size: 15)
        case 5: return .system(size: 14)
        case 6: return .system(size: 13)
        case 7: return .system(size: 12)
        case 8: return .system(size: 11)
        case 9: return .system(size: 11)
        case 10: return .system(size: 10)
        default: return .system(size: 14)
        }
        #endif
    }

    static func contentDescriptionFont(for columns: Int) -> Font {
        #if os(iOS)
        if isIPad {
            switch columns {
            case 3: return .system(size: 14)
            case 4: return .system(size: 13)
            case 5: return .system(size: 12)
            case 6: return .system(size: 11)
            case 7: return .system(size: 11)
            case 8: return .system(size: 10)
            case 9: return .system(size: 10)
            case 10: return .system(size: 9)
            default: return .system(size: 12)
            }
        } else {
            switch columns {
            case 2: return .system(size: 13)
            case 3: return .system(size: 11)
            case 4: return .system(size: 10)
            default: return .system(size: 13)
            }
        }
        #else
        switch columns {
        case 3: return .system(size: 14)
        case 4: return .system(size: 13)
        case 5: return .system(size: 12)
        case 6: return .system(size: 11)
        case 7: return .system(size: 11)
        case 8: return .system(size: 10)
        case 9: return .system(size: 10)
        case 10: return .system(size: 9)
        default: return .system(size: 12)
        }
        #endif
    }

    static func contentTitleLineLimit(for columns: Int) -> Int {
        #if os(iOS)
        if isIPad {
            switch columns {
            case 3: return 10
            case 4: return 8
            case 5: return 6
            case 6: return 5
            case 7: return 5
            case 8: return 4
            case 9: return 4
            case 10: return 3
            default: return 6
            }
        } else {
            switch columns {
            case 2: return 8
            case 3: return 6
            case 4: return 4
            default: return 8
            }
        }
        #else
        switch columns {
        case 3: return 10
        case 4: return 8
        case 5: return 6
        case 6: return 5
        case 7: return 5
        case 8: return 4
        case 9: return 4
        case 10: return 3
        default: return 6
        }
        #endif
    }

    static func contentDescriptionLineLimit(for columns: Int) -> Int {
        #if os(iOS)
        if isIPad {
            switch columns {
            case 3: return 10
            case 4: return 8
            case 5: return 6
            case 6: return 5
            case 7: return 5
            case 8: return 4
            case 9: return 4
            case 10: return 3
            default: return 6
            }
        } else {
            switch columns {
            case 2: return 8
            case 3: return 6
            case 4: return 4
            default: return 8
            }
        }
        #else
        switch columns {
        case 3: return 10
        case 4: return 8
        case 5: return 6
        case 6: return 5
        case 7: return 5
        case 8: return 4
        case 9: return 4
        case 10: return 3
        default: return 6
        }
        #endif
    }

    static func contentSpacing(for columns: Int) -> CGFloat {
        #if os(iOS)
        if isIPad {
            switch columns {
            case 3: return 14
            case 4: return 12
            case 5: return 10
            case 6: return 8
            case 7: return 7
            case 8: return 6
            case 9: return 5
            case 10: return 4
            default: return 10
            }
        } else {
            switch columns {
            case 2: return 8
            case 3: return 4
            case 4: return 4
            default: return 8
            }
        }
        #else
        switch columns {
        case 3: return 14
        case 4: return 12
        case 5: return 10
        case 6: return 8
        case 7: return 7
        case 8: return 6
        case 9: return 5
        case 10: return 4
        default: return 10
        }
        #endif
    }

    static func contentPadding(for columns: Int) -> CGFloat {
        #if os(iOS)
        if isIPad {
            switch columns {
            case 3: return 16
            case 4: return 14
            case 5: return 12
            case 6: return 11
            case 7: return 10
            case 8: return 9
            case 9: return 8
            case 10: return 7
            default: return 12
            }
        } else {
            switch columns {
            case 2: return 16
            case 3: return 10
            case 4: return 8
            default: return 16
            }
        }
        #else
        switch columns {
        case 3: return 16
        case 4: return 14
        case 5: return 12
        case 6: return 11
        case 7: return 10
        case 8: return 9
        case 9: return 8
        case 10: return 7
        default: return 12
        }
        #endif
    }

    static func contentIconSize(for columns: Int) -> CGFloat {
        #if os(iOS)
        if isIPad {
            switch columns {
            case 3: return 36
            case 4: return 32
            case 5: return 28
            case 6: return 26
            case 7: return 24
            case 8: return 22
            case 9: return 20
            case 10: return 18
            default: return 28
            }
        } else {
            switch columns {
            case 2: return 40
            case 3: return 28
            case 4: return 20
            default: return 40
            }
        }
        #else
        switch columns {
        case 3: return 36
        case 4: return 32
        case 5: return 28
        case 6: return 26
        case 7: return 24
        case 8: return 22
        case 9: return 20
        case 10: return 18
        default: return 28
        }
        #endif
    }

    static func contentIconContainerSize(for columns: Int) -> CGFloat {
        #if os(iOS)
        if isIPad {
            switch columns {
            case 3: return 90
            case 4: return 80
            case 5: return 70
            case 6: return 65
            case 7: return 60
            case 8: return 55
            case 9: return 50
            case 10: return 45
            default: return 70
            }
        } else {
            switch columns {
            case 2: return 100
            case 3: return 70
            case 4: return 50
            default: return 100
            }
        }
        #else
        switch columns {
        case 3: return 90
        case 4: return 80
        case 5: return 70
        case 6: return 65
        case 7: return 60
        case 8: return 55
        case 9: return 50
        case 10: return 45
        default: return 70
        }
        #endif
    }

    // MARK: - iPad Drawer Width
    #if os(iOS)
    /// Calcule la largeur du drawer pour iPad selon l'orientation et la taille d'écran
    static func drawerWidth(for screenWidth: CGFloat, screenHeight: CGFloat) -> CGFloat {
        guard isIPad else {
            // iPhone : 80% de la largeur
            return screenWidth * 0.8
        }

        // iPad : adapter selon l'orientation
        let isLandscape = screenWidth > screenHeight

        if isLandscape {
            // Paysage : ouvrir moins (environ 30-35% max 400pt)
            return min(screenWidth * 0.30, 400)
        } else {
            // Portrait : un peu plus (environ 40-45% max 450pt)
            return min(screenWidth * 0.40, 450)
        }
    }

    /// Largeur maximale du floating menu sur iPad
    static func floatingMenuMaxWidth(for screenWidth: CGFloat) -> CGFloat? {
        guard isIPad else { return nil }
        // Limiter à 600pt ou 70% de la largeur, le plus petit des deux
        return min(600, screenWidth * 0.7)
    }
    #endif
}
