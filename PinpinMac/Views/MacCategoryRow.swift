//
//  MacCategoryRow.swift
//  PinpinMac
//
//  Ligne de catégorie stylisée comme sur iPhone avec menu contextuel et mode édition
//

import SwiftUI

struct MacCategoryRow: View {
    let title: String
    let isSelected: Bool
    let isEmpty: Bool
    let action: () -> Void
    var onRename: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    var canDelete: Bool = true
    var isEditing: Bool = false
    
    @State private var isHovered = false
    
    private var hasContextMenu: Bool {
        onRename != nil || onDelete != nil
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Bouton de suppression en mode édition (à gauche)
            if isEditing && canDelete {
                Button {
                    onDelete?()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
            
            HStack(spacing: 8) {
                // Indicateur de sélection (petit point) - masqué en mode édition
                if isSelected && !isEditing {
                    Circle()
                        .fill(isEmpty ? Color.secondary : Color(nsColor: .labelColor))
                        .frame(width: 6, height: 6)
                        .transition(.scale.combined(with: .opacity))
                        .padding(.top, 2)
                }
                
                // Titre
                Text(title)
                    .font(.system(size: 24, weight: .semibold))
                    .lineLimit(1)
                    .opacity(isEmpty ? 0.3 : 1.0)
            }
        }
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: isEditing)
        .pointerStyle(.link)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            if isEditing {
                // En mode édition, clic pour renommer
                onRename?()
            } else {
                // En mode normal, clic pour sélectionner
                withAnimation(.easeInOut(duration: 0.2)) {
                    action()
                }
            }
        }
        .if(hasContextMenu && !isEditing) { view in
            view.contextMenu {
                if let onRename = onRename {
                    Button {
                        onRename()
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                }
                
                if let onDelete = onDelete, canDelete {
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


