//
//  RenameCategorySheet.swift
//  Pinpin
//
//  Sheet moderne pour créer/renommer une catégorie
//

import SwiftUI

struct RenameCategorySheet: View {
    @Binding var name: String
    let onCancel: () -> Void
    let onSave: () -> Void
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                VStack(spacing: 40) {
                    TextField("Category Name", text: $name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.horizontal, 40)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .focused($isFieldFocused)
                        .onSubmit {
                            // Vérifier que le nom n'est pas vide avant de sauvegarder
                            if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                onSave()
                            }
                        }
                }
                
                Spacer()
            }
            .background(Color(UIColor.systemBackground))
            .ignoresSafeArea(.all)
            .animation(.easeInOut(duration: 0.3), value: name.isEmpty)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isFieldFocused = true
                }
            }
        }
    }
}
