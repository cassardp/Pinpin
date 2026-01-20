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
        ZStack(alignment: .topTrailing) {
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
            .overlay {
                if isSelectionMode {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            isSelected ? Color.accentColor : Color.clear,
                            lineWidth: 3
                        )
                        .animation(.snappy(duration: 0.2), value: isSelected)
                }
            }
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
            
            // Checkbox overlay (selection mode)
            if isSelectionMode {
                checkboxOverlay
            }
        }
    }
    
    private var checkboxOverlay: some View {
        ZStack {
            Circle()
                .fill(.regularMaterial)
                .frame(width: 28, height: 28)
            
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(isSelected ? .white : .secondary)
                .symbolRenderingMode(.hierarchical)
                .background {
                    if isSelected {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 28, height: 28)
                    }
                }
        }
        .padding(8)
        .transition(.scale.combined(with: .opacity))
    }
}
