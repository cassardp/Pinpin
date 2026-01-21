//
//  MacSidebarMenu.swift
//  PinpinMac
//
//  Bouton "Add Category" en bas de la sidebar
//

import SwiftUI

struct MacSidebarMenu: View {
    // Action
    let onAddCategory: () -> Void
    
    var body: some View {
        Button {
            onAddCategory()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 17, weight: .medium))
        }
        .buttonStyle(.borderless)
        .frame(width: 44, height: 44)
        .background(.regularMaterial, in: Circle())
        .overlay {
            Circle()
                .strokeBorder(.quaternary.opacity(0.5), lineWidth: 0.5)
        }
        .help("Add Category")
    }
}
