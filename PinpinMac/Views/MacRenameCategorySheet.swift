//
//  MacRenameCategorySheet.swift
//  PinpinMac
//
//  Sheet pour créer/renommer une catégorie sur Mac
//

import SwiftUI

struct MacRenameCategorySheet: View {
    @Binding var name: String
    let isEditing: Bool
    let onCancel: () -> Void
    let onSave: () -> Void
    
    private var title: String {
        isEditing ? "Rename Category" : "New Category"
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text(title)
                .font(.headline)
            
            TextField("Category Name", text: $name)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)
                .onSubmit {
                    if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSave()
                    }
                }
            
            HStack(spacing: 16) {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Save") {
                    onSave()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(minWidth: 350)
    }
}
