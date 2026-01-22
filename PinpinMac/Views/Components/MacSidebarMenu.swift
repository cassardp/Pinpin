//
//  MacSidebarMenu.swift
//  PinpinMac
//
//  Boutons "Add Category" et "Edit Categories" en bas de la sidebar
//

import SwiftUI

struct MacSidebarMenu: View {
    // Actions
    let onAddCategory: () -> Void
    @Binding var isEditingCategories: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Bouton Add Category
            Button {
                onAddCategory()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background(.regularMaterial, in: Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(.quaternary.opacity(0.5), lineWidth: 0.5)
                    }
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Add Category")
            
            // Bouton Edit Categories
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isEditingCategories.toggle()
                }
            } label: {
                Image(systemName: isEditingCategories ? "checkmark" : "pencil")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background(.regularMaterial, in: Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(.quaternary.opacity(0.5), lineWidth: 0.5)
                    }
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .help(isEditingCategories ? "Done Editing" : "Edit Categories")
        }
    }
}
