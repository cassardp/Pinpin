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
    @State private var selectedCategory: String? = nil
    
    private let coreDataService = CoreDataService.shared
    
    var body: some View {
        // Categories List - ScrollView prend tout l'espace
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
                                    isSelected: selectedCategory == categoryName
                                ) {
                                    handleCategorySelection(categoryName)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 40)
                    .padding(.bottom, 100)
                }
                .background(Color(UIColor.systemBackground))
                .ignoresSafeArea(.all)
        .onAppear {
            loadCategories()
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategorySheet { categoryName in
                addCategory(categoryName)
                // Ne pas sélectionner automatiquement - laisser l'utilisateur choisir
            }
        }
    }
    
    private func loadCategories() {
        let categoryNames = coreDataService.fetchCategoryNames()
        
        // Trier les catégories par nombre d'items (décroissant)
        categories = categoryNames.sorted { categoryA, categoryB in
            let countA = coreDataService.countItems(for: categoryA)
            let countB = coreDataService.countItems(for: categoryB)
            return countA > countB
        }
    }
    
    private func addCategory(_ name: String) {
        coreDataService.addCategory(name: name)
        loadCategories() // Recharger la liste
    }
    
    private func handleCategorySelection(_ categoryName: String) {
        // Haptic feedback léger
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Marquer la catégorie comme sélectionnée avec animation
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedCategory = categoryName
        }
        
        // Délai de 0.8 seconde pour laisser voir la sélection et permettre le chargement
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            onCategorySelected(categoryName)
        }
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var firstImageURL: String? = nil
    @State private var itemCount: Int = 0
    private let coreDataService = CoreDataService.shared
    
    // Couleur simple basée sur le hash du nom (fallback)
    private var categoryColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .cyan, .indigo, .mint]
        let hash = abs(title.hashValue)
        return colors[hash % colors.count]
    }
    
    var body: some View {
        HStack(spacing: 32) {
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
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                // Fichier local non trouvé
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(categoryColor.opacity(0.1))
                                        .frame(width: 60, height: 60)
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
                                    .frame(width: 60, height: 60)
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
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        case .failure(_):
                            // Erreur de chargement
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(categoryColor.opacity(0.1))
                                    .frame(width: 60, height: 60)
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
                                    .frame(width: 60, height: 60)
                                ProgressView()
                                    .scaleEffect(0.7)
                            }
                        @unknown default:
                            // Fallback
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(categoryColor.opacity(0.1))
                                    .frame(width: 60, height: 60)
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
                                .frame(width: 60, height: 60)
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
                            .frame(width: 60, height: 60)
                        Text(String(title.prefix(1).uppercased()))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(categoryColor)
                    }
                }
                
                // Titre dans le style FilterMenuView
                VStack(alignment: .leading, spacing: 2) {
                    Text(title.capitalized)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text("\(itemCount) PIN\(itemCount > 1 ? "S" : "")")
                        .font(.system(size: 12))
                        .fontWeight(.medium)
                        .foregroundColor(.secondary.opacity(0.6))
                }
                
                Spacer()
                
                // Checkmark si sélectionné
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .transition(.scale.combined(with: .opacity))
                }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
        .scaleEffect(isSelected ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .onAppear {
            loadFirstImage()
            loadCategoryCount()
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
            HStack(spacing: 32) {
                // Icône d'ajout
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.black)
                        .foregroundColor(.primary)
                }
                
                // Texte simplifié
                VStack(alignment: .leading, spacing: 2) {
                    Text("New")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                
                Spacer()
                

            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemBackground).opacity(0.5))
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
        VStack {
            Spacer()
            
            VStack(spacing: 40) {
                // Champ texte centré
                TextField("Category Name", text: $categoryName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.horizontal, 40)
                
                // Bouton Add qui apparaît quand le champ n'est pas vide
                if !categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button("Add") {
                        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                        onCategoryAdded(trimmedName)
                        dismiss()
                    }
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.primary.opacity(0.1))
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            
            Spacer()
        }
        .background(Color(UIColor.systemBackground))
        .ignoresSafeArea(.all)
        .animation(.easeInOut(duration: 0.3), value: categoryName.isEmpty)
    }
}

