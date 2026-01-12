//
//  MacPinterestLayout.swift
//  PinpinMac
//
//  Layout Pinterest/Masonry personnalisé pour macOS
//

import SwiftUI

struct MacPinterestLayout: Layout {
    let numberOfColumns: Int
    let itemSpacing: CGFloat
    
    struct Cache {
        var itemHeights: [CGFloat] = []
        var cardWidth: CGFloat = 0
    }
    
    init(numberOfColumns: Int = 4, itemSpacing: CGFloat = 16) {
        self.numberOfColumns = max(1, numberOfColumns)
        self.itemSpacing = itemSpacing
    }
    
    func makeCache(subviews: Subviews) -> Cache {
        Cache()
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        let safeProposalWidth = proposal.replacingUnspecifiedDimensions().width
        let totalSpacing = itemSpacing * CGFloat(numberOfColumns - 1)
        let cardWidth = (safeProposalWidth - totalSpacing) / CGFloat(numberOfColumns)
        
        cache.cardWidth = cardWidth
        cache.itemHeights.removeAll(keepingCapacity: true)
        cache.itemHeights.reserveCapacity(subviews.count)
        
        var columnHeights = [CGFloat](repeating: 0.0, count: numberOfColumns)
        
        for subView in subviews {
            let height = subView.sizeThatFits(.init(width: cardWidth, height: nil)).height
            cache.itemHeights.append(height)
            
            let columnIndex = columnHeights.enumerated().min(by: { $0.element < $1.element })!.offset
            
            if columnHeights[columnIndex] > 0 {
                columnHeights[columnIndex] += itemSpacing
            }
            
            columnHeights[columnIndex] += height
        }
        
        return CGSize(
            width: safeProposalWidth,
            height: columnHeights.max() ?? 0
        )
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        let cardWidth = cache.cardWidth
        var yOffset = [CGFloat](repeating: bounds.minY, count: numberOfColumns)
        
        for (index, subView) in subviews.enumerated() {
            let columnIndex = yOffset.enumerated().min(by: { $0.element < $1.element })!.offset
            let x = bounds.minX + (cardWidth + itemSpacing) * CGFloat(columnIndex)
            let height = cache.itemHeights[index]
            let y = yOffset[columnIndex]
            
            subView.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(width: cardWidth, height: height)
            )
            
            yOffset[columnIndex] += height + itemSpacing
        }
    }
}
