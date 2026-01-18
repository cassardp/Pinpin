//
//  MacContentCard.swift
//  PinpinMac
//
//  Carte de contenu pour macOS avec effet hover
//

import SwiftUI

struct MacContentCard: View {
    let item: ContentItem
    let numberOfColumns: Int
    let isHovered: Bool
    let onTap: () -> Void
    let onOpenURL: () -> Void
    
    var body: some View {
        ContentCardView(
            item: item,
            numberOfColumns: numberOfColumns,
            isSelectionMode: false
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(
            color: isHovered ? Color.black.opacity(0.2) : Color.black.opacity(0.08),
            radius: isHovered ? 16 : 6,
            y: isHovered ? 8 : 2
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
        .onTapGesture(count: 2) {
            onOpenURL()
        }
        .onTapGesture(count: 1) {
            onTap()
        }
    }
}
