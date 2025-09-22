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
    @Binding var isSwipingHorizontally: Bool
    var onOpenAbout: () -> Void
    
    @State private var isSwipeActionsOpen = false
    
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
                    
                    // Fermer les swipe actions si ouvertes
                    if isSwipeActionsOpen {
                        isSwipeActionsOpen = false
                        isSwipingHorizontally = false
                    }
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
                    title: "All",
                    isSwipingHorizontally: isSwipingHorizontally
                ) {
                    selectedContentType = nil
                }
                .swipeActions(edge: .leading) {
                    Button("Select") {
                        selectedContentType = nil
                        isSwipeActionsOpen = false
                    }
                    .tint(.blue)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                
                // Types dynamiques avec réorganisation native
                ForEach(availableTypes, id: \.self) { type in
                    CategoryListRow(
                        isSelected: selectedContentType == type,
                        title: type.capitalized,
                        isSwipingHorizontally: isSwipingHorizontally
                    ) {
                        selectedContentType = (selectedContentType == type) ? nil : type
                    }
                    .swipeActions(edge: .leading) {
                        Button("Select") {
                            selectedContentType = (selectedContentType == type) ? nil : type
                            isSwipeActionsOpen = false
                        }
                        .tint(.blue)
                        
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
            .contentMargins(.vertical, 100)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Détecter un swipe horizontal vers la gauche (ouverture des actions)
                        if value.translation.width < -20 && abs(value.translation.height) < 10 {
                            if !isSwipeActionsOpen {
                                isSwipeActionsOpen = true
                                isSwipingHorizontally = true
                            }
                        }
                        // Détecter un swipe horizontal vers la droite (fermeture des actions)
                        else if value.translation.width > 20 && abs(value.translation.height) < 10 && isSwipeActionsOpen {
                            // Ne pas fermer le menu, juste marquer qu'on ferme les actions
                            isSwipingHorizontally = true
                        }
                    }
                    .onEnded { value in
                        // Si c'était un swipe vers la droite pour fermer les actions
                        if value.translation.width > 20 && isSwipeActionsOpen {
                            isSwipeActionsOpen = false
                            isSwipingHorizontally = false
                        }
                        // Sinon, petit délai pour permettre aux swipe actions de se fermer naturellement
                        else {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                if isSwipeActionsOpen {
                                    isSwipeActionsOpen = false
                                    isSwipingHorizontally = false
                                }
                            }
                        }
                    }
            )
            .onChange(of: isSwipeActionsOpen) { _, newValue in
                isSwipingHorizontally = newValue
            }
            
        }
    }
}

// MARK: - CategoryListRow Component
struct CategoryListRow: View {
    let isSelected: Bool
    let title: String
    let isSwipingHorizontally: Bool
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
        isSwipingHorizontally: .constant(false),
        onOpenAbout: {}
    )
}
