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
    let isSelectionMode: Bool
    let isSelected: Bool
    let onTap: () -> Void
    let onToggleSelection: () -> Void
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
        ZStack(alignment: .topLeading) {
            ContentCardView(
                item: item,
                numberOfColumns: numberOfColumns,
                isSelectionMode: false
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(
                color: isHovered ? Color.black.opacity(0.2) : Color.black.opacity(0.08),
                radius: isHovered ? 16 : 16,
                y: isHovered ? 8 : 2
            )
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
            .onTapGesture {
                if isSelectionMode {
                    onToggleSelection()
                } else if hasExternalLink {
                    onOpenURL()
                }
            }
            .if(!isSelectionMode && hasExternalLink) { view in
                view.pointerStyle(.link)
            }
            
            // Checkbox overlay en haut à gauche (style iOS)
            if isSelectionMode {
                checkboxOverlay
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            }
        }
        .contentShape(Rectangle())
        .clipped()
    }

    // Style identique à iOS : checkmark rouge en haut à gauche
    private var checkboxOverlay: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                onToggleSelection()
            }
        }) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .red : .gray)
                .font(.system(size: 22))
                .scaleEffect(isSelected ? 1.0 : 0.9)
                .background(Color.white.opacity(0.9))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(.plain)
        .padding(8)
        .contentTransition(.symbolEffect(.replace))
    }
}
