//
//  CategorySelectionModalWrapper.swift
//  PinpinShareExtension
//
//  Wrapper SwiftUI pour la modale de sélection de catégorie dans l'extension
//

import SwiftUI
import SwiftData

struct CategorySelectionModalWrapper: View {
    let contentData: SharedContentData
    @Binding var isProcessing: Bool
    let onCategorySelected: (String) -> Void
    let onCancel: () -> Void
    
    @State private var categories: [String] = []
    @State private var showingAddCategory = false
    @State private var newCategoryName = ""
    @State private var selectedCategory: String? = nil
    
    private let dataService = DataService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Indicateur de traitement en haut
            if isProcessing {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Processing content...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Categories List - ScrollView prend tout l'espace
            ScrollView {
                VStack(spacing: 16) {
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
        }
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
        let categoryNames = dataService.fetchCategoryNames()
        
        // Filtrer les catégories : masquer "Misc" si elle est vide
        let filteredCategories = categoryNames.filter { categoryName in
            if categoryName.lowercased() == "misc" {
                let itemCount = dataService.countItems(for: categoryName)
                return itemCount > 0 // Masquer Misc si vide
            }
            return true // Garder toutes les autres catégories
        }
        
        // Trier les catégories par nombre d'items (décroissant)
        categories = filteredCategories.sorted { categoryA, categoryB in
            let countA = dataService.countItems(for: categoryA)
            let countB = dataService.countItems(for: categoryB)
            return countA > countB
        }
    }
    
    private func addCategory(_ name: String) {
        dataService.addCategory(name: name)
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
        
        // Si le traitement est en cours, attendre qu'il se termine
        if isProcessing {
            print("[CategoryModal] Traitement en cours, attente...")
            // Vérifier toutes les 0.5 secondes si le traitement est terminé
            checkProcessingAndProceed(categoryName: categoryName)
        } else {
            // Délai de 0.8 seconde pour laisser voir la sélection
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                onCategorySelected(categoryName)
            }
        }
    }
    
    private func checkProcessingAndProceed(categoryName: String) {
        if !isProcessing {
            // Traitement terminé, procéder
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onCategorySelected(categoryName)
            }
        } else {
            // Continuer à attendre
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                checkProcessingAndProceed(categoryName: categoryName)
            }
        }
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var firstImageData: Data? = nil
    @State private var itemCount: Int = 0
    private let dataService = DataService.shared
    
    // Style uniforme pour les catégories sans items (comme l'icône d'ajout)
    private var fallbackIconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary.opacity(0.1))
                .frame(width: 60, height: 60)
            
            Text(String(title.prefix(1).uppercased()))
                .font(.title2)
                .fontWeight(.black)
                .foregroundColor(.primary)
        }
    }
    
    var body: some View {
        HStack(spacing: 32) {
            // Image de prévisualisation depuis SwiftData ou fallback
            if let imageData = firstImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                // Fallback : première lettre si pas d'image
                fallbackIconView
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
            loadFirstImageData()
            loadCategoryCount()
        }
    }
    
    private func loadCategoryCount() {
        // Compter les vrais items pour cette catégorie
        itemCount = dataService.countItems(for: title)
    }
    
    private func loadFirstImageData() {
        // Récupérer la première image de la catégorie depuis SwiftData
        firstImageData = dataService.fetchFirstImageData(for: title)
    }
}

// MARK: - Add Category Card
struct AddCategoryCard: View {
    let action: () -> Void
    
    var body: some View {
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
                Text("Add a category")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .frame(height: 70) // Hauteur fixe identique à CategoryCard
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
}

// MARK: - Add Category Sheet
struct AddCategorySheet: View {
    @State private var categoryName = ""
    @Environment(\.dismiss) private var dismiss
    let onCategoryAdded: (String) -> Void
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                VStack(spacing: 40) {
                    TextField("Category Name", text: $categoryName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.horizontal, 40)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .focused($isFieldFocused)
                }
                
                Spacer()
            }
            .background(Color(UIColor.systemBackground))
            .ignoresSafeArea(.all)
            .animation(.easeInOut(duration: 0.3), value: categoryName.isEmpty)
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        categoryName = ""
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmedName.isEmpty else { return }
                        onCategoryAdded(trimmedName)
                        categoryName = ""
                        dismiss()
                    }
                    .disabled(categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                categoryName = ""
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isFieldFocused = true
                }
            }
        }
    }
}

