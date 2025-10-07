//
//  PinterestLayout.swift
//  Pinpin
//
//  Layout Pinterest personnalisé utilisant le protocole Layout de SwiftUI
//  Target: iOS 18+
//

import SwiftUI

struct PinterestLayout: Layout {
    let numberOfColumns: Int
    let itemSpacing: CGFloat
    
    init(numberOfColumns: Int = 2, itemSpacing: CGFloat = 10) {
        self.numberOfColumns = numberOfColumns
        self.itemSpacing = itemSpacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let safeProposalWidth = proposal.replacingUnspecifiedDimensions().width
        let totalSpacing = itemSpacing * CGFloat(numberOfColumns - 1)
        let cardWidth = (safeProposalWidth - totalSpacing) / CGFloat(numberOfColumns)
        
        var columnHeights = [CGFloat](repeating: 0.0, count: numberOfColumns)
        
        for subView in subviews {
            // 1. Calculer la hauteur de la subview basée sur sa largeur
            let height = subView.sizeThatFits(.init(width: cardWidth, height: nil)).height
            
            // 2. Trouver la colonne avec la hauteur minimale
            let columnIndex = columnHeights.enumerated().min(by: { $0.element < $1.element })!.offset
            
            // 3. Ajouter l'espacement si la colonne contient déjà des éléments
            if columnHeights[columnIndex] > 0 {
                columnHeights[columnIndex] += itemSpacing
            }
            
            // 4. Ajouter la hauteur de l'élément à la colonne
            columnHeights[columnIndex] += height
        }
        
        return CGSize(
            width: safeProposalWidth,
            height: columnHeights.max() ?? 0
        )
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let safeProposalWidth = proposal.replacingUnspecifiedDimensions().width
        let totalSpacing = itemSpacing * CGFloat(numberOfColumns - 1)
        let cardWidth = (safeProposalWidth - totalSpacing) / CGFloat(numberOfColumns)
        
        var yOffset = [CGFloat](repeating: bounds.minY, count: numberOfColumns)
        
        for subView in subviews {
            // 1. Trouver la colonne avec l'offset Y minimal (colonne la plus courte)
            let columnIndex = yOffset.enumerated().min(by: { $0.element < $1.element })!.offset
            
            // 2. Calculer la position X basée sur l'index de la colonne
            let x = bounds.minX + (cardWidth + itemSpacing) * CGFloat(columnIndex)
            
            let height = subView.sizeThatFits(.init(width: cardWidth, height: nil)).height
            let y = yOffset[columnIndex]
            
            // 3. Placer la subview à la position calculée
            subView.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(width: cardWidth, height: height)
            )
            
            // 4. Mettre à jour l'offset Y pour cette colonne
            yOffset[columnIndex] += height + itemSpacing
        }
    }
}

// Wrapper simplifié pour iOS 18+
struct PinterestLayoutWrapper<Content: View>: View {
    let content: Content
    let numberOfColumns: Int
    let itemSpacing: CGFloat
    
    init(numberOfColumns: Int = 2, itemSpacing: CGFloat = 10, @ViewBuilder content: () -> Content) {
        self.numberOfColumns = numberOfColumns
        self.itemSpacing = itemSpacing
        self.content = content()
    }
    
    var body: some View {
        PinterestLayout(numberOfColumns: numberOfColumns, itemSpacing: itemSpacing) {
            content
        }
    }
}
