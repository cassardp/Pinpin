//
//  CategorySelectionModalWrapper.swift
//  PinpinShareExtension
//
//  Wrapper SwiftUI pour la modale de sélection de catégorie dans l'extension
//

import SwiftUI
import CoreData

struct CategorySelectionModalWrapper: View {
    let contentData: SharedContentData
    let onCategorySelected: (String) -> Void
    let onCancel: () -> Void
    
    @State private var categories: [String] = []
    @State private var showingAddCategory = false
    @State private var newCategoryName = ""
    
    private let coreDataService = CoreDataService.shared
    
    var body: some View {
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
                            ForEach(categories, id: \.self) { categoryName in
                                CategoryCard(
                                    title: categoryName,
                                    isSelected: false
                                ) {
                                    onCategorySelected(categoryName)
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
        categories = coreDataService.fetchCategoryNames()
    }
    
    private func addCategory(_ name: String) {
        coreDataService.addCategory(name: name)
        loadCategories() // Recharger la liste
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var itemCount: Int = 0
    @State private var firstImageURL: String? = nil
    private let coreDataService = CoreDataService.shared
    
    // Couleur simple basée sur le hash du nom (fallback)
    private var categoryColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .cyan, .indigo, .mint]
        let hash = abs(title.hashValue)
        return colors[hash % colors.count]
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Image de prévisualisation ou fallback
                if let imageURL = firstImageURL {
                    // Vérifier si c'est un chemin local (images/...)
                    if imageURL.hasPrefix("images/") {
                        // Image locale dans App Group
                        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.misericode.pinpin") {
                            let fullURL = containerURL.appendingPathComponent(imageURL)
                            if let uiImage = UIImage(contentsOfFile: fullURL.path) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                // Fichier local non trouvé
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(categoryColor.opacity(0.1))
                                        .frame(width: 50, height: 50)
                                    Text(String(title.prefix(1).uppercased()))
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(categoryColor)
                                }
                            }
                        } else {
                            // Pas d'accès App Group
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(categoryColor.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                Text(String(title.prefix(1).uppercased()))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(categoryColor)
                            }
                        }
                    } else if let url = URL(string: imageURL) {
                        // URL web - utiliser AsyncImage
                        AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        case .failure(_):
                            // Erreur de chargement
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(categoryColor.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                Text(String(title.prefix(1).uppercased()))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(categoryColor)
                            }
                        case .empty:
                            // Placeholder pendant le chargement
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(categoryColor.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                ProgressView()
                                    .scaleEffect(0.7)
                            }
                        @unknown default:
                            // Fallback
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(categoryColor.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                Text(String(title.prefix(1).uppercased()))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(categoryColor)
                            }
                        }
                        }
                    } else {
                        // URL invalide
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(categoryColor.opacity(0.1))
                                .frame(width: 50, height: 50)
                            Text(String(title.prefix(1).uppercased()))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(categoryColor)
                        }
                    }
                } else {
                    // Fallback : première lettre si pas d'image
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(categoryColor.opacity(0.1))
                            .frame(width: 50, height: 50)
                        Text(String(title.prefix(1).uppercased()))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(categoryColor)
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
                    
                    // Debug supprimé - tout fonctionne ! 🎉
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
            loadFirstImage()
        }
    }
    
    private func loadCategoryCount() {
        // Compter les vrais items pour cette catégorie
        itemCount = coreDataService.countItems(for: title)
    }
    
    private func loadFirstImage() {
        // Récupérer la première image de la catégorie
        firstImageURL = coreDataService.fetchFirstImageURL(for: title)
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

