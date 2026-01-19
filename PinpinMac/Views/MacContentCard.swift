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
    
    private var hasExternalLink: Bool {
        guard let urlString = item.url, !urlString.isEmpty else { return false }
        
        // Exclure les liens internes Supabase (images uploadées)
        if urlString.contains("supabase.co") && urlString.contains("/storage/v1/object") {
            return false
        }
        
        // Exclure les liens locaux
        if urlString.hasPrefix("file://") {
            return false
        }
        
        return true
    }
    
    var body: some View {
        ContentCardView(
            item: item,
            numberOfColumns: numberOfColumns,
            isSelectionMode: false
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(
            color: isHovered ? Color.black.opacity(0.2) : Color.black.opacity(0.08),
            radius: isHovered ? 16 : 6,
            y: isHovered ? 8 : 2
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
        .onTapGesture {
            if hasExternalLink {
                onOpenURL()
            }
        }
        .if(hasExternalLink) { view in
            view.pointerStyle(.link)
        }
    }
}
