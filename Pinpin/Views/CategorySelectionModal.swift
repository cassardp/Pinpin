//
//  CategorySelectionModal.swift
//  Pinpin
//
//  Modale de sélection de catégorie après partage (style Pinterest/TikTok)
//

import SwiftUI

struct CategorySelectionModal: View {
    @StateObject private var dataService = DataService.shared
    @State private var categoryNames: [String] = []
    @State private var showingAddCategory = false
    @State private var newCategoryName = ""
    @Environment(\.dismiss) private var dismiss
    
    let onCategorySelected: (String) -> Void
    
    init(defaultCategory: String? = nil, onCategorySelected: @escaping (String) -> Void) {
        self.onCategorySelected = onCategorySelected
    }
    
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
                    
                    Button(action: { dismiss() }) {
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
                        
                        if categoryNames.isEmpty {
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
                            ForEach(categoryNames, id: \.self) { categoryName in
                                CategoryCard(
                                    title: categoryName,
                                    isSelected: false
                                ) {
                                    onCategorySelected(categoryName)
                                    dismiss()
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
        }
        .onAppear {
            loadCategoryNames()
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategorySheet { categoryName in
                dataService.addCategory(name: categoryName)
                loadCategoryNames()
                onCategorySelected(categoryName)
                dismiss()
            }
        }
    }
    
    // MARK: - Actions
    private func loadCategoryNames() {
        categoryNames = dataService.fetchCategoryNames()
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @StateObject private var dataService = DataService.shared
    @State private var randomItem: ContentItem?
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
                    
                    if let item = randomItem, let thumbnailUrl = item.thumbnailUrl, !thumbnailUrl.isEmpty {
                        // Afficher l'image réelle du dernier item
                        AsyncImage(url: URL(string: thumbnailUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            // Placeholder simple pendant le chargement
                            RoundedRectangle(cornerRadius: 8)
                                .fill(categoryColor.opacity(0.3))
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.8)
                                )
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        // Pas d'image disponible - placeholder coloré simple
                        RoundedRectangle(cornerRadius: 8)
                            .fill(categoryColor.opacity(0.3))
                            .overlay(
                                Text(String(title.prefix(1).uppercased()))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(categoryColor)
                            )
                            .frame(width: 50, height: 50)
                    }
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
            loadCategoryData()
        }
    }
    
    private func loadCategoryData() {
        randomItem = dataService.getRandomItemForCategory(title)
        itemCount = dataService.getItemCountForCategory(title)
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


// MARK: - Preview
#Preview {
    CategorySelectionModal { category in
        print("Selected category: \(category)")
    }
}
