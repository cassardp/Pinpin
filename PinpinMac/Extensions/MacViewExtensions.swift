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
    
    /// Applique un effet Liquid Glass avec border subtile (macOS 26)
    func liquidGlassEffect<S: InsettableShape>(
        _ shape: S,
        material: Material = .regular
    ) -> some View {
        self
            .background(material, in: shape)
            .overlay {
                shape
                    .strokeBorder(.quaternary.opacity(0.5), lineWidth: 0.5)
            }
    }
    
    /// Style de bouton Liquid Glass circulaire
    func liquidGlassButton(size: CGFloat = 36) -> some View {
        self
            .frame(width: size, height: size)
            .buttonStyle(.borderless)
            .liquidGlassEffect(Circle())
    }
    
    /// Style de bouton Liquid Glass capsule
    func liquidGlassCapsule(
        horizontalPadding: CGFloat = 16,
        verticalPadding: CGFloat = 10
    ) -> some View {
        self
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .buttonStyle(.borderless)
            .liquidGlassEffect(Capsule())
    }
}
