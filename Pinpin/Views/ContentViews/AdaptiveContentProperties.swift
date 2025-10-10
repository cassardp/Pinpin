//
//  AdaptiveContentProperties.swift
//  Pinpin
//
//  Propriétés adaptatives pour les vues de contenu selon le nombre de colonnes
//

import SwiftUI

struct AdaptiveContentProperties {
    let numberOfColumns: Int
    
    var font: Font {
        switch numberOfColumns {
        case 2: return .body
        case 3: return .callout
        case 4: return .caption
        default: return .body
        }
    }
    
    var descriptionFont: Font {
        switch numberOfColumns {
        case 2: return .caption
        case 3: return .caption2
        case 4: return .caption2
        default: return .caption
        }
    }
    
    var lineLimit: Int {
        switch numberOfColumns {
        case 2: return 8
        case 3: return 6
        case 4: return 6
        default: return 8
        }
    }
    
    var descriptionLineLimit: Int {
        switch numberOfColumns {
        case 2: return 8
        case 3: return 6
        case 4: return 6
        default: return 8
        }
    }
    
    var spacing: CGFloat {
        switch numberOfColumns {
        case 2: return 8
        case 3: return 6
        case 4: return 4
        default: return 8
        }
    }
    
    var padding: CGFloat {
        switch numberOfColumns {
        case 2: return 16
        case 3: return 12
        case 4: return 8
        default: return 16
        }
    }
    
    var iconSize: CGFloat {
        switch numberOfColumns {
        case 2: return 40
        case 3: return 32
        case 4: return 24
        default: return 40
        }
    }
    
    var iconContainerSize: CGFloat {
        switch numberOfColumns {
        case 2: return 100
        case 3: return 80
        case 4: return 60
        default: return 100
        }
    }
}
