//
//  PlatformColors.swift
//  Pinpin
//
//  Extensions pour les couleurs multi-platform
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Color {
    /// Couleur de fond système (compatible iOS & macOS)
    static var systemBackground: Color {
        #if os(macOS)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color(UIColor.systemBackground)
        #endif
    }
    
    /// Couleur de fond secondaire système (compatible iOS & macOS)
    static var secondarySystemBackground: Color {
        #if os(macOS)
        return Color(NSColor.controlBackgroundColor)
        #else
        return Color(UIColor.secondarySystemBackground)
        #endif
    }
    
    /// Convertit une Color SwiftUI vers PlatformColor (UIColor ou NSColor)
    func toPlatformColor() -> PlatformColor {
        #if os(macOS)
        return NSColor(self)
        #else
        return UIColor(self)
        #endif
    }
}

extension ToolbarItemPlacement {
    /// Placement trailing compatible multi-platform
    static var trailingCompat: ToolbarItemPlacement {
        #if os(macOS)
        return .automatic
        #else
        return .navigationBarTrailing
        #endif
    }
    
    /// Placement leading compatible multi-platform
    static var leadingCompat: ToolbarItemPlacement {
        #if os(macOS)
        return .automatic
        #else
        return .navigationBarLeading
        #endif
    }
}
