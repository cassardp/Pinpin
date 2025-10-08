//
//  TextOnlyContentView.swift
//  Pinpin
//
//  Vue spécialisée pour le contenu texte uniquement (sans image)
//

import SwiftUI

// MARK: - View Extension
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

struct TextOnlyContentView: View {
    let item: ContentItem
    let numberOfColumns: Int
    let isSelectionMode: Bool
    @State private var showingEditSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: adaptiveSpacing) {
            // Titre principal
            Text(item.bestTitle)
                .font(adaptiveFont)
                .foregroundColor(postItColors.textColor)
                .multilineTextAlignment(.leading)
                .lineLimit(adaptiveLineLimit)
            
            // Description si disponible et différente du titre
            if let description = item.itemDescription, 
               !description.isEmpty,
               description != item.title {
                Text(description)
                    .font(adaptiveDescriptionFont)
                    .foregroundColor(postItColors.textColor.opacity(0.8))
                    .multilineTextAlignment(.leading)
                    .lineLimit(adaptiveDescriptionLineLimit)
            }
        }
        .padding(adaptivePadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(postItColors.backgroundColor)
        )
        .contentShape(Rectangle())
        .if(!isSelectionMode) { view in
            view
                .onTapGesture {
                    showingEditSheet = true
                }
                .sheet(isPresented: $showingEditSheet) {
                    TextEditSheet(item: item)
                }
        }
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
        guard let components = UIColor(color).cgColor.components else {
            return Color.primary
        }
        
        let r = components[0] * factor
        let g = components[1] * factor
        let b = components[2] * factor
        
        return Color(red: r, green: g, blue: b)
    }
    
    // MARK: - Adaptive Properties
    
    private var adaptiveFont: Font {
        switch numberOfColumns {
        case 2: return .body
        case 3: return .callout
        case 4: return .caption
        default: return .body // fallback pour 2 colonnes
        }
    }
    
    private var adaptiveDescriptionFont: Font {
        switch numberOfColumns {
        case 2: return .caption
        case 3: return .caption2
        case 4: return .caption2
        default: return .caption // fallback pour 2 colonnes
        }
    }
    
    private var adaptiveLineLimit: Int {
        switch numberOfColumns {
        case 2: return 8
        case 3: return 6
        case 4: return 6
        default: return 8 // fallback pour 2 colonnes
        }
    }
    
    private var adaptiveDescriptionLineLimit: Int {
        switch numberOfColumns {
        case 2: return 8
        case 3: return 6
        case 4: return 6
        default: return 8 // fallback pour 2 colonnes
        }
    }
    
    private var adaptiveSpacing: CGFloat {
        switch numberOfColumns {
        case 2: return 8
        case 3: return 6
        case 4: return 4
        default: return 8 // fallback pour 2 colonnes
        }
    }
    
    private var adaptivePadding: CGFloat {
        switch numberOfColumns {
        case 2: return 16
        case 3: return 12
        case 4: return 8
        default: return 16 // fallback pour 2 colonnes
        }
    }
    
}