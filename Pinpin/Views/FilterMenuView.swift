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
            
            // ScrollView avec effet de fondu
            ZStack {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Spacer initial pour le safe area
                        Spacer()
                            .frame(height: 150)
                        
                        // Option "Tout"
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            withAnimation(.easeInOut) {
                                selectedContentType = nil
                            }
                        }) {
                            HStack(spacing: 12) {
                                if selectedContentType == nil {
                                    Circle()
                                        .fill(Color.primary)
                                        .frame(width: 8, height: 8)
                                        .transition(.move(edge: .leading).combined(with: .opacity))
                                }

                                Text("All")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)

                                Spacer()
                            }
                            .padding(.horizontal, 32)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .allowsHitTesting(!isSwipingHorizontally)
                        
                        // Types dynamiques
                        ForEach(availableTypes, id: \.self) { type in
                            Button(action: {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                // Toggle : si le type est déjà sélectionné, on désélectionne
                                withAnimation(.easeInOut) {
                                    selectedContentType = (selectedContentType == type) ? nil : type
                                }
                            }) {
                                HStack(spacing: 12) {
                                    if selectedContentType == type {
                                        Circle()
                                            .fill(Color.primary)
                                            .frame(width: 8, height: 8)
                                            .transition(.move(edge: .leading).combined(with: .opacity))
                                    }

                                    Text(ContentType(rawValue: type)?.displayName ?? type.capitalized)
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)

                                    Spacer()
                                }
                                .padding(.horizontal, 32)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .allowsHitTesting(!isSwipingHorizontally)
                        }
                        
                        // Spacer final pour permettre le scroll
                        Spacer()
                            .frame(height: 300)
                    }
                }
                
                // Effet de fondu en haut
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
                
                // Effet de fondu en bas
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
}

// MARK: - Preview
#Preview {
    FilterMenuView(
        selectedContentType: .constant(nil),
        isSwipingHorizontally: .constant(false),
        onOpenAbout: {}
    )
}
