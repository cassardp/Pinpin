//
//  MacAddMenu.swift
//  PinpinMac
//
//  Menu "+" contextuel pour ajouter Note ou Category
//

import SwiftUI

struct MacAddMenu: View {
    let isSidebarVisible: Bool
    let onAddNote: () -> Void
    let onAddCategory: () -> Void
    
    var body: some View {
        Menu {
            Button {
                onAddNote()
            } label: {
                Label("Add Note", systemImage: "note.text.badge.plus")
            }
            
            if isSidebarVisible {
                Button {
                    onAddCategory()
                } label: {
                    Label("Add Category", systemImage: "folder.badge.plus")
                }
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
        }
        .menuStyle(.borderlessButton)
        .frame(width: 24, height: 24)
    }
}
