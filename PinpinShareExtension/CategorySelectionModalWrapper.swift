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
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.sortOrder, order: .forward)
    private var allCategories: [Category]
    
    @State private var showingAddCategory = false
    @State private var newCategoryName = ""
    @State private var selectedCategory: String? = nil
    
    private var categories: [String] {
        // Filtrer et trier les catégories
        let filtered = allCategories.filter { category in
            if category.name.lowercased() == "misc" {
                return (category.contentItems?.count ?? 0) > 0
            }
            return true
        }
        
        return filtered
            .sorted { ($0.contentItems?.count ?? 0) > ($1.contentItems?.count ?? 0) }
            .map { $0.name }
    }
    
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
                
                    ForEach(categories, id: \.self) { categoryName in
                        CategoryCard(
                            title: categoryName,
                            isSelected: selectedCategory == categoryName
                        ) {
                            handleCategorySelection(categoryName)
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
        .sheet(isPresented: $showingAddCategory) {
            RenameCategorySheet { categoryName in
                addCategory(categoryName)
                // Sélectionner automatiquement la nouvelle catégorie et ajouter l'item dedans
                handleCategorySelection(categoryName)
            }
        }
    }
    
    
    private func addCategory(_ name: String) {
        let newCategory = Category(name: name)
        modelContext.insert(newCategory)
        try? modelContext.save()
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
    
    @Environment(\.modelContext) private var modelContext
    @State private var firstImageData: Data? = nil
    @State private var itemCount: Int = 0
    
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
        let descriptor = FetchDescriptor<ContentItem>(
            predicate: #Predicate { $0.category?.name == title }
        )
        itemCount = (try? modelContext.fetchCount(descriptor)) ?? 0
    }
    
    private func loadFirstImageData() {
        var descriptor = FetchDescriptor<ContentItem>(
            predicate: #Predicate { item in
                item.category?.name == title && item.imageData != nil
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        
        if let item = try? modelContext.fetch(descriptor).first {
            firstImageData = item.imageData
        }
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
                Text("Add")
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

// MARK: - Rename Category Sheet
struct RenameCategorySheet: View {
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
                        .onSubmit {
                            // Validation par le bouton du clavier
                            let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmedName.isEmpty else { return }
                            onCategoryAdded(trimmedName)
                            categoryName = ""
                            dismiss()
                        }
                }
                
                Spacer()
            }
            .background(Color(UIColor.systemBackground))
            .ignoresSafeArea(.all)
            .animation(.easeInOut(duration: 0.3), value: categoryName.isEmpty)
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

