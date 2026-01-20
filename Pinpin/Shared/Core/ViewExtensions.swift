//
//  ViewExtensions.swift
//  Pinpin
//
//  Extensions SwiftUI communes iOS & macOS
//

import SwiftUI

extension View {
    /// Applique conditionnellement une transformation à une vue
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
