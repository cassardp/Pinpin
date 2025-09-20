//
//  FilterMenuView.swift
//  Neeed2
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
    @Binding var selectedContentType: String?
    @Binding var isSwipingHorizontally: Bool
    var onOpenAbout: () -> Void
    
    // Récupère les types uniques depuis les données
    private var availableTypes: [String] {
        let types = contentItems.compactMap { $0.contentType }
        let uniqueTypes = Set(types)
        
        // Utiliser l'ordre défini dans ContentType avec misc en dernier
        // Ne jamais masquer "misc" du menu - on veut pouvoir y accéder pour gérer les contenus
        return ContentType.orderedCases
            .map { $0.rawValue }
            .filter { uniqueTypes.contains($0) }
    }
    
    // Compte les items par type
    private func countForType(_ type: String?) -> Int {
        if type == nil {
            // Pour "All", exclure "misc" si l'option est activée
            if userPreferences.hideMiscCategory {
                return contentItems.filter { $0.contentType != "misc" }.count
            } else {
                return contentItems.count
            }
        }
        return contentItems.filter { $0.contentType == type }.count
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
            
            // VStack centré verticalement
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                
                // Option "Tout"
                CategoryButton(
                    isSelected: selectedContentType == nil,
                    title: "All",
                    isSwipingHorizontally: isSwipingHorizontally
                ) {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    withAnimation(.easeInOut) {
                        selectedContentType = nil
                    }
                }
                
                // Types dynamiques
                ForEach(availableTypes, id: \.self) { type in
                    CategoryButton(
                        isSelected: selectedContentType == type,
                        title: ContentType(rawValue: type)?.displayName ?? type.capitalized,
                        isSwipingHorizontally: isSwipingHorizontally
                    ) {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        withAnimation(.easeInOut) {
                            selectedContentType = (selectedContentType == type) ? nil : type
                        }
                    }
                }
                
                Spacer()
            }
            
            // Effet de fondu en haut - en dehors de la ScrollView
            VStack {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(UIColor.systemBackground), location: 0.0),
                        .init(color: Color(UIColor.systemBackground).opacity(0.9), location: 0.3),
                        .init(color: Color.clear, location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
                .allowsHitTesting(false)
                
                Spacer()
            }
            
            // Effet de fondu en bas - en dehors de la ScrollView
            VStack {
                Spacer()
                
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.clear, location: 0.0),
                        .init(color: Color(UIColor.systemBackground).opacity(0.8), location: 0.7),
                        .init(color: Color(UIColor.systemBackground), location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
                .allowsHitTesting(false)
            }
        }
    }
}

// MARK: - CategoryButton Component
struct CategoryButton: View {
    let isSelected: Bool
    let title: String
    let isSwipingHorizontally: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: action) {
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
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isSwipingHorizontally)
            
            Spacer()
        }
        .padding(.horizontal, 32)
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
