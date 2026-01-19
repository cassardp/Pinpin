//
//  MacCategoryRow.swift
//  PinpinMac
//
//  Ligne de catégorie stylisée comme sur iPhone avec menu contextuel
//

import SwiftUI

struct MacCategoryRow: View {
    let title: String
    let isSelected: Bool
    let isEmpty: Bool
    let action: () -> Void
    var onRename: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    @State private var isHovered = false
    
    private var hasContextMenu: Bool {
        onRename != nil || onDelete != nil
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Indicateur de sélection (petit point)
            if isSelected {
                Circle()
                    .frame(width: 6, height: 6)
                    .transition(.scale.combined(with: .opacity))
                    .padding(.top, 2)
            }
            
            // Titre
            Text(title)
                .font(.system(size: 24, weight: .semibold))
                .lineLimit(1)
        }
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .opacity(isEmpty ? 0.3 : 1.0)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .pointerStyle(.link)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                action()
            }
        }
        .if(hasContextMenu) { view in
            view.contextMenu {
                if let onRename = onRename {
                    Button {
                        onRename()
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                }
                
                if let onDelete = onDelete {
                    Divider()
                    
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
}


