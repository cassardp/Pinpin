//
//  TextEditSheet.swift
//  Pinpin
//
//  Sheet d'édition en plein écran pour les éléments texte
//

import SwiftUI
import SwiftData

struct TextEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let item: ContentItem?
    let targetCategory: Category?

    @State private var editedTitle: String
    @State private var editedDescription: String
    @FocusState private var isTextFieldFocused: Bool

    init(item: ContentItem? = nil, targetCategory: Category? = nil) {
        self.item = item
        self.targetCategory = targetCategory
        self._editedTitle = State(initialValue: item?.title ?? "")
        self._editedDescription = State(initialValue: item?.itemDescription ?? "")
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Zone d'édition principale
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Titre uniquement
                        TextField("Enter text", text: $editedTitle, axis: .vertical)
                            .textFieldStyle(.plain)
                            .font(.title2)
                            .focused($isTextFieldFocused)
                    }
                    .padding(32)
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 500, minHeight: 400)
        #endif
        .onAppear {
            // Auto-focus sur le champ titre
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
    
    // MARK: - Actions

    private func saveChanges() {
        let cleanTitle = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanTitle.isEmpty else { return }

        if let existingItem = item {
            // Mode édition : mettre à jour l'item existant
            existingItem.title = cleanTitle
        } else {
            // Mode création : créer un nouvel item seulement si le texte n'est pas vide
            let newItem = ContentItem(
                title: cleanTitle,
                itemDescription: nil,
                url: nil,
                thumbnailUrl: nil,
                imageData: nil,
                category: targetCategory
            )
            modelContext.insert(newItem)
        }

        try? modelContext.save()
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
