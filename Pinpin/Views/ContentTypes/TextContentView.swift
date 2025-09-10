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
    
    // Taille de police dynamique selon le nombre de colonnes
    private var dynamicFontSize: Font {
        switch numberOfColumns {
        case 1: return .title2
        case 2: return .body
        case 3: return .callout
        case 4: return .caption
        default: return .body
        }
    }
    
    var body: some View {
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
        .padding(16)
        .background(.primary)
        .sheet(isPresented: $showingTextModal) {
            TextDetailModal(text: item.metadataDict["best_description"] ?? item.itemDescription ?? "")
        }
    }
}
