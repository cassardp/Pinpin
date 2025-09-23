//
//  FilterMenuView.swift
//  Pinpin
//
//  Menu latéral de filtrage par type de contenu
//

import SwiftUI
import CoreData

struct FilterMenuView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ContentItem.createdAt, ascending: false)],
        animation: .default)
    private var contentItems: FetchedResults<ContentItem>
    
    @StateObject private var userPreferences = UserPreferences.shared
    @StateObject private var categoryOrderService = CategoryOrderService.shared
    @Binding var selectedContentType: String?
    var onOpenAbout: () -> Void
    
    // Récupère les catégories utilisées depuis les données avec ordre personnalisé
    private var availableTypes: [String] {
        let types = contentItems.compactMap { $0.safeCategoryName }
        let uniqueTypes = Set(types)
        let availableCategories = Array(uniqueTypes)
        
        // Appliquer l'ordre personnalisé
        return categoryOrderService.orderedCategories(from: availableCategories)
    }
    
    // Compte les items par type
    private func countForType(_ type: String?) -> Int {
        if type == nil {
            return contentItems.count
        }
        return contentItems.filter { $0.safeCategoryName == type }.count
    }
    
    // Méthode pour déplacer les catégories (fonctionnalité native SwiftUI)
    private func moveCategories(from source: IndexSet, to destination: Int) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            categoryOrderService.reorderCategories(from: source, to: destination)
        }
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
                .onTapGesture {
                    // Perdre le focus du TextField
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            
            // Liste centrée verticalement - solution simple
            List {
                // Spacer invisible pour centrer
                Color.clear
                    .frame(height: 0)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                
                // Option "Tout"
                CategoryListRow(
                    isSelected: selectedContentType == nil,
                    title: "All"
                ) {
                    selectedContentType = nil
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                
                // Types dynamiques avec réorganisation native
                ForEach(availableTypes, id: \.self) { type in
                    CategoryListRow(
                        isSelected: selectedContentType == type,
                        title: type.capitalized
                    ) {
                        selectedContentType = (selectedContentType == type) ? nil : type
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .onMove(perform: moveCategories)
                
                // Spacer invisible pour centrer
                Color.clear
                    .frame(height: 0)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentMargins(.vertical, 60)
            
        }
    }
}

// MARK: - CategoryListRow Component
struct CategoryListRow: View {
    let isSelected: Bool
    let title: String
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                if isSelected {
                    Circle()
                        .fill(Color.primary)
                        .frame(width: 8, height: 8)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }

                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .padding(.vertical, -4)
            
            Spacer()
        }
        .padding(.horizontal, 32)
        .contentShape(Rectangle())
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(.easeInOut) {
                action()
            }
        }
    }
}


// MARK: - Preview
#Preview {
    FilterMenuView(
        selectedContentType: .constant(nil),
        onOpenAbout: {}
    )
}
