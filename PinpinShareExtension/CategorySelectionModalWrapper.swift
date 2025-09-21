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
    @State private var showingAddCategory = false
    @State private var newCategoryName = ""
    
    // Plus de catégories par défaut - utilise seulement celles sauvegardées
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Add to category")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Choose where to save this content")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { onCancel() }) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .frame(width: 30, height: 30)
                            .background(Color(UIColor.secondarySystemBackground))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Categories List
                ScrollView {
                    LazyVStack(spacing: 8) {
                        // Add Category Button (en haut)
                        AddCategoryCard {
                            showingAddCategory = true
                        }
                        
                        if categories.isEmpty {
                            // Message quand pas de catégories
                            VStack(spacing: 12) {
                                Image(systemName: "folder.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                
                                Text("No categories yet")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Create your first category to organize your content")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 40)
                        } else {
                            ForEach(categories, id: \.self) { category in
                                CategoryCard(
                                    title: category,
                                    isSelected: false
                                ) {
                                    onCategorySelected(category)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 24)
                
                Spacer(minLength: 34)
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
                onCategorySelected(categoryName)
            }
        }
    }
    
    private func loadCategories() {
        if let sharedDefaults = UserDefaults(suiteName: "group.com.misericode.pinpin"),
           let savedCategories = sharedDefaults.array(forKey: "user_categories") as? [String] {
            categories = savedCategories
        } else {
            categories = []
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
    
    @State private var itemCount: Int = 0
    
    // Couleur basée sur le hash du nom de la catégorie pour avoir une couleur consistante
    private var categoryColor: Color {
        let colors: [Color] = [.red, .blue, .green, .orange, .purple, .pink, .cyan, .indigo, .mint, .teal]
        let hash = abs(title.hashValue)
        return colors[hash % colors.count]
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Image de prévisualisation
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(categoryColor.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    // Pour l'extension, on utilise un placeholder avec la première lettre
                    Text(String(title.prefix(1).uppercased()))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(categoryColor)
                }
                
                // Titre et nombre de publications
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text("\(itemCount) item\(itemCount > 1 ? "s" : "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Flèche d'action
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            loadCategoryCount()
        }
    }
    
    private func loadCategoryCount() {
        // Pour l'extension, on simule le nombre ou on pourrait accéder aux UserDefaults partagés
        itemCount = Int.random(in: 1...25)
    }
}

// MARK: - Add Category Card
struct AddCategoryCard: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icône d'ajout
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "plus")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                }
                
                // Texte
                VStack(alignment: .leading, spacing: 2) {
                    Text("Create a new category")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text("Organize your content")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Flèche
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground).opacity(0.5))
            )
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
                    Text("Category name")
                        .font(.headline)
                    
                    TextField("e.g. Recipes, Travel, Inspiration...", text: $categoryName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Spacer()
            }
            .padding(24)
            .navigationTitle("New category")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
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

