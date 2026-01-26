//
//  TextOnlyContentView.swift
//  Pinpin
//
//  Vue spécialisée pour le contenu texte uniquement (sans image)
//

import SwiftUI

struct TextOnlyContentView: View {
    let item: ContentItem
    let numberOfColumns: Int
    let isSelectionMode: Bool
    @State private var showingEditSheet = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.contentSpacing(for: numberOfColumns)) {
            // Titre principal (pas de description affichée pour les notes)
            Text(item.bestTitle)
                .font(AppConstants.contentTitleFont(for: numberOfColumns))
                .foregroundColor(postItColors.textColor)
                .multilineTextAlignment(.leading)
                .lineLimit(AppConstants.contentTitleLineLimit(for: numberOfColumns))
        }
        .padding(AppConstants.contentPadding(for: numberOfColumns))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(postItColors.backgroundColor)
        )
        .contentShape(Rectangle())
        #if os(iOS)
        .if(!isSelectionMode) { view in
            view
                .onTapGesture {
                    showingEditSheet = true
                }
                .sheet(isPresented: $showingEditSheet) {
                    TextEditSheet(item: item)
                }
        }
        #endif
    }
    
    // MARK: - Post-it Colors

    /// Couleurs Post-it adaptatives (clair/sombre)
    private var postItColors: (backgroundColor: Color, textColor: Color) {
        if colorScheme == .dark {
            // Dark mode : brun doré chaud
            let bgColor = Color(red: 0.35, green: 0.28, blue: 0.15)
            let textColor = Color(red: 1.0, green: 0.92, blue: 0.75)
            return (bgColor, textColor)
        } else {
            // Light mode : pêche/vanille #FFE5B4
            let bgColor = Color(red: 1.0, green: 0.898, blue: 0.706)
            let textColor = darkenColor(bgColor, factor: 0.4)
            return (bgColor, textColor)
        }
    }
    
    /// Assombrit une couleur en réduisant ses composantes RGB
    private func darkenColor(_ color: Color, factor: Double) -> Color {
        #if os(macOS)
        let nsColor = NSColor(color)
        guard let components = nsColor.usingColorSpace(.sRGB)?.cgColor.components else {
            return Color.primary
        }
        #else
        let uiColor = UIColor(color)
        guard let components = uiColor.cgColor.components else {
            return Color.primary
        }
        #endif
        
        let r = components[0] * factor
        let g = components[1] * factor
        let b = components[2] * factor
        
        return Color(red: r, green: g, blue: b)
    }
}