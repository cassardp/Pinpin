//
//  MacViewExtensions.swift
//  PinpinMac
//
//  Extensions SwiftUI spécifiques macOS
//

import SwiftUI
import AppKit

extension View {
    /// Définit le style du curseur sur macOS
    func pointerStyle(_ style: NSCursor) -> some View {
        self.onHover { hovering in
            if hovering {
                style.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
