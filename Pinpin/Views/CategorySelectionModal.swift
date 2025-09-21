//
//  CategorySelectionModal.swift
//  Pinpin
//
//  Modale de sélection de catégorie après partage (style Pinterest/TikTok)
//

import SwiftUI

struct CategorySelectionModal: View {
    @ObservedObject var categoryService = CategoryService.shared
    @State private var selectedCategory: String = ""
    @State private var showingAddCategory = false
    @State private var newCategoryName = ""
    @Environment(\.dismiss) private var dismiss
    
    let onCategorySelected: (String) -> Void
    
    init(defaultCategory: String? = nil, onCategorySelected: @escaping (String) -> Void) {
        self.onCategorySelected = onCategorySelected
        self._selectedCategory = State(initialValue: defaultCategory ?? CategoryService.shared.defaultCategory)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("Enregistrer dans")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Choisissez une catégorie pour organiser votre contenu")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Categories Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(categoryService.categories, id: \.self) { category in
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
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(selectedCategory.isEmpty)
                    
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .background(Color(UIColor.systemBackground))
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategorySheet { categoryName in
                categoryService.addCategory(categoryName)
                selectedCategory = categoryName
            }
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

// MARK: - Preview
#Preview {
    CategorySelectionModal { category in
        print("Selected category: \(category)")
    }
}
