//
//  TextContentView.swift
//  Neeed2
//
//  Specialized view for text content type
//

import SwiftUI

struct TextContentView: View {
    let item: ContentItem
    let numberOfColumns: Int
    @State private var showingTextModal = false
    @State private var refreshTrigger = 0
    
    // Taille de police dynamique selon le nombre de colonnes
    private var dynamicFontSize: Font {
        switch numberOfColumns {
        case 1: return .system(size: 18)
        case 2: return .system(size: 16)
        case 3: return .system(size: 14)
        case 4: return .system(size: 12)
        default: return .system(size: 16)
        }
    }
    
    // Padding horizontal dynamique selon le nombre de colonnes
    private var dynamicHorizontalPadding: CGFloat {
        switch numberOfColumns {
        case 1: return 20
        case 2: return 14
        case 3: return 12
        case 4: return 8
        default: return 16
        }
    }
    
    // Padding vertical dynamique selon le nombre de colonnes
    private var dynamicVerticalPadding: CGFloat {
        switch numberOfColumns {
        case 1: return 20
        case 2: return 16
        case 3: return 14
        case 4: return 10
        default: return 16
        }
    }
    
    var body: some View {
        ZStack {
            // Background inversé selon le mode
            Color.primary
            
            VStack(alignment: .leading, spacing: 12) {
                // Description - utiliser la meilleure disponible
                let bestDescription = item.metadataDict["best_description"] ?? item.itemDescription
                if let description = bestDescription, !description.isEmpty {
                    Text(description)
                        .font(dynamicFontSize)
                        .foregroundStyle(Color(UIColor.systemBackground))
                        .lineLimit(6)
                        .multilineTextAlignment(.leading)
                        .onTapGesture {
                            showingTextModal = true
                        }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, dynamicHorizontalPadding)
            .padding(.vertical, dynamicVerticalPadding)
        }
        // Dégradé overlay inversé selon le mode
        .overlay(
            LinearGradient(
                colors: [Color.clear, Color.primary.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        )
        .sheet(isPresented: $showingTextModal) {
            TextDetailModal(item: item) {
                refreshTrigger += 1
            }
        }
        .id(refreshTrigger)
    }
}
