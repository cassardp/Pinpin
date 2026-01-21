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
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.horizontal, 40)
                        #if os(iOS)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        #endif
                        .focused($isFieldFocused)
                        .onSubmit {
                            // Vérifier que le nom n'est pas vide avant de sauvegarder
                            if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                onSave()
                            }
                        }
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 120)
                .padding(.bottom, 60)
                
                Spacer()
            }
            #if os(iOS)
            .background(Color(UIColor.systemBackground))
            #else
            .background(Color(.windowBackgroundColor))
            #endif
            .ignoresSafeArea(.all)
            .animation(.easeInOut(duration: 0.3), value: name.isEmpty)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
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
