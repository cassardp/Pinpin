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
    
    /// Couleurs Post-it jaune-orange chaud
    private var postItColors: (backgroundColor: Color, textColor: Color) {
        // Jaune-orange chaud style bento : #FFE5B4 (ton pêche/vanille)
        let bgColor = Color(red: 1.0, green: 0.898, blue: 0.706)
        
        // Calculer une variante foncée pour le texte
        let textColor = darkenColor(bgColor, factor: 0.4)
        
        return (bgColor, textColor)
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