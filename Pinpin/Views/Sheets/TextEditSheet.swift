//
//  TextEditSheet.swift
//  Pinpin
//
//  Sheet d'édition en plein écran pour les éléments texte
//

import SwiftUI

struct TextEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let item: ContentItem
    
    @State private var editedTitle: String
    @State private var editedDescription: String
    @FocusState private var isTextFieldFocused: Bool
    
    init(item: ContentItem) {
        self.item = item
        self._editedTitle = State(initialValue: item.title)
        self._editedDescription = State(initialValue: item.itemDescription ?? "")
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Zone d'édition principale
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Titre uniquement
                        TextField("Enter text", text: $editedTitle, axis: .vertical)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .focused($isTextFieldFocused)
                            .padding(20)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            // Auto-focus sur le champ titre
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveChanges() {
        // Nettoyer le texte
        let cleanTitle = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Sauvegarder les modifications
        item.title = cleanTitle
        item.updatedAt = Date()
        
        // Sauvegarder dans le contexte
        do {
            try modelContext.save()
        } catch {
            print("Erreur lors de la sauvegarde: \(error)")
        }
    }
}

#Preview {
    let item = ContentItem(
        title: "Exemple de titre",
        itemDescription: "Exemple de description",
        url: nil,
        thumbnailUrl: nil,
        imageData: nil
    )
    
    TextEditSheet(item: item)
}
