//
//  AppConstants.swift
//  Pinpin
//
//  Constantes partagées entre l'app et l'extension
//

import Foundation
import CoreGraphics

enum AppConstants {
    // MARK: - App Groups & CloudKit
    static let groupID = "group.com.misericode.pinpin"
    static let cloudKitContainerID = "iCloud.com.misericode.Pinpin"
    
    // MARK: - File Names
    static let pendingContentFileName = "pending_shared_contents.json"
    static let newContentFlagFileName = "has_new_content.flag"
    
    // MARK: - Darwin Notifications
    static let newContentNotificationName = "com.misericode.pinpin.newcontent" as CFString
    
    // MARK: - Image Optimization
    static let maxImageSize: CGFloat = 1024
    static let maxImageBytes = 1_000_000
    static let defaultCompressionQuality: CGFloat = 0.8
    static let minimumCompressionQuality: CGFloat = 0.1
    
    // MARK: - Pagination
    static let itemsPerPage = 50
    
    // MARK: - Category Names
    static let miscCategoryNames = ["Misc"]
    static let defaultCategoryName = "Misc"
    
    // MARK: - User Defaults Keys
    static let categoryOrderKey = "categoryOrder"
    static let numberOfColumnsKey = "numberOfColumns"
    
    // MARK: - Layout
    static let minColumns = 2
    static let maxColumns = 4
    static let defaultColumns = 2
}
