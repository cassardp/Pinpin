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
    var onOpenSettings: () -> Void
    var onOpenAbout: () -> Void
    
    // Récupère les types uniques depuis les données
    private var availableTypes: [String] {
        let types = contentItems.compactMap { $0.contentType }
        return Array(Set(types)).sorted()
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
            
            VStack(alignment: .leading, spacing: 16) {

                
                Button(action: {
                    onOpenAbout()
                }) {
                    HStack {
                        Text("")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 24)
                }
                .buttonStyle(PlainButtonStyle())
                .allowsHitTesting(!isSwipingHorizontally)
                
                Spacer()
                
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
                
                Button(action: {
                    onOpenSettings()
                }) {
                    HStack {
                        Text("Settings")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 24)
                }
                .buttonStyle(PlainButtonStyle())
                .allowsHitTesting(!isSwipingHorizontally)
                

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
        onOpenSettings: {},
        onOpenAbout: {}
    )
}
