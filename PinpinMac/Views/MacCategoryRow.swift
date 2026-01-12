//
//  MacCategoryRow.swift
//  PinpinMac
//
//  Ligne de catégorie stylisée comme sur iPhone
//

import SwiftUI

struct MacCategoryRow: View {
    let title: String
    let isSelected: Bool
    let isEmpty: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Indicateur de sélection (petit point)
            if isSelected {
                Circle()
                    .fill(isEmpty ? Color.secondary : Color.primary)
                    .frame(width: 8, height: 8)
                    .transition(.scale.combined(with: .opacity))
            }
            
            // Titre
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(isEmpty ? .secondary : .primary)
                .lineLimit(1)
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .opacity(isEmpty ? 0.6 : 1.0)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                action()
            }
        }
    }
}
