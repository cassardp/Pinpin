//
//  CategorySelectionModalWrapper.swift
//  PinpinShareExtension
//
//  Wrapper SwiftUI pour la modale de sélection de catégorie dans l'extension
//

import SwiftUI

struct CategorySelectionModalWrapper: View {
    let contentData: SharedContentData
    let onCategorySelected: (String) -> Void
    let onCancel: () -> Void
    
    @State private var categories: [String] = []
    @State private var selectedCategory: String = ""
    @State private var showingAddCategory = false
    @State private var newCategoryName = ""
    
    // Catégories par défaut si aucune n'est trouvée
    private let defaultCategories = [
        "Favoris", "À lire", "Inspiration", "Recettes", 
        "Voyage", "Shopping", "Travail", "Personnel"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header avec aperçu du contenu
                VStack(spacing: 16) {
                    Text("Enregistrer dans")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    // Aperçu du contenu
                    VStack(alignment: .leading, spacing: 8) {
                        Text(contentData.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(2)
                        
                        if let url = contentData.url {
                            Text(url)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Categories Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(categories, id: \.self) { category in
                            CategoryCard(
                                title: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                        
                        // Add Category Button
                        AddCategoryCard {
                            showingAddCategory = true
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 24)
                
                // Bottom Actions
                VStack(spacing: 12) {
                    Button("Enregistrer") {
                        onCategorySelected(selectedCategory)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(selectedCategory.isEmpty)
                    
                    Button("Annuler") {
                        onCancel()
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .background(Color(UIColor.systemBackground))
            .navigationBarHidden(true)
        }
        .onAppear {
            loadCategories()
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategorySheet { categoryName in
                addCategory(categoryName)
                selectedCategory = categoryName
            }
        }
    }
    
    private func loadCategories() {
        if let sharedDefaults = UserDefaults(suiteName: "group.com.misericode.pinpin"),
           let savedCategories = sharedDefaults.array(forKey: "user_categories") as? [String],
           !savedCategories.isEmpty {
            categories = savedCategories
            selectedCategory = savedCategories.first ?? ""
        } else {
            categories = defaultCategories
            selectedCategory = defaultCategories.first ?? ""
        }
    }
    
    private func addCategory(_ name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty && !categories.contains(trimmedName) else { return }
        
        categories.append(trimmedName)
        
        // Sauvegarder dans UserDefaults partagés
        if let sharedDefaults = UserDefaults(suiteName: "group.com.misericode.pinpin") {
            sharedDefaults.set(categories, forKey: "user_categories")
            sharedDefaults.synchronize()
        }
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.accentColor : Color(UIColor.secondarySystemBackground))
                        .frame(height: 80)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "folder")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Add Category Card
struct AddCategoryCard: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(height: 80)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    )
                
                Text("Nouvelle\ncatégorie")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Add Category Sheet
struct AddCategorySheet: View {
    @State private var categoryName = ""
    @Environment(\.dismiss) private var dismiss
    let onCategoryAdded: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nom de la catégorie")
                        .font(.headline)
                    
                    TextField("Ex: Recettes, Voyage, Inspiration...", text: $categoryName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Spacer()
            }
            .padding(24)
            .navigationTitle("Nouvelle catégorie")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Ajouter") {
                        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmedName.isEmpty {
                            onCategoryAdded(trimmedName)
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Primary Button Style
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.accentColor)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
