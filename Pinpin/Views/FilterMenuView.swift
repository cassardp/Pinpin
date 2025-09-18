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
    
    @Binding var selectedContentType: String?
    @Binding var isSwipingHorizontally: Bool
    var onOpenAbout: () -> Void
    
    // Récupère les types uniques depuis les données
    private var availableTypes: [String] {
        let types = contentItems.compactMap { $0.contentType }
        let uniqueTypes = Set(types)
        
        // Utiliser l'ordre défini dans ContentType avec misc en dernier
        return ContentType.orderedCases
            .map { $0.rawValue }
            .filter { uniqueTypes.contains($0) }
    }
    
    // Compte les items par type
    private func countForType(_ type: String?) -> Int {
        if type == nil {
            return contentItems.count
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
            
            VStack(alignment: .leading, spacing: 16) {
                Spacer()
                    .frame(height: 66) // Safe area top spacing
                
                Spacer() // Spacer pour centrer verticalement
                
                // Option "Tout"
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    withAnimation(.easeInOut) {
                        selectedContentType = nil
                    }
                }) {
                    HStack(spacing: 8) {
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
                    .padding(.horizontal, 24)
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
                        HStack(spacing: 8) {
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
                        .padding(.horizontal, 24)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .allowsHitTesting(!isSwipingHorizontally)
                }
                
                Spacer()
                

            }
            .padding(.bottom, 32)
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
