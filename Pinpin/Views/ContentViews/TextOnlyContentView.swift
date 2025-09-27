//
//  TextOnlyContentView.swift
//  Pinpin
//
//  Vue spécialisée pour le contenu texte uniquement (sans image)
//

import SwiftUI

struct TextOnlyContentView: View {
    let item: ContentItem
    let numberOfColumns: Int
    @State private var showingEditSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: adaptiveSpacing) {
            // Titre principal
            Text(item.bestTitle)
                .font(adaptiveFont)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(adaptiveLineLimit)
            
            // Description si disponible et différente du titre
            if let description = item.itemDescription, 
               !description.isEmpty,
               description != item.title {
                Text(description)
                    .font(adaptiveDescriptionFont)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(adaptiveDescriptionLineLimit)
            }
        }
        .padding(adaptivePadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            showingEditSheet = true
        }
        .sheet(isPresented: $showingEditSheet) {
            TextEditSheet(item: item)
        }
    }
    
    // MARK: - Adaptive Properties
    
    private var adaptiveFont: Font {
        switch numberOfColumns {
        case 2: return .body
        case 3: return .callout
        case 4: return .caption
        default: return .body // fallback pour 2 colonnes
        }
    }
    
    private var adaptiveDescriptionFont: Font {
        switch numberOfColumns {
        case 2: return .caption
        case 3: return .caption2
        case 4: return .caption2
        default: return .caption // fallback pour 2 colonnes
        }
    }
    
    private var adaptiveLineLimit: Int {
        switch numberOfColumns {
        case 2: return 8
        case 3: return 6
        case 4: return 6
        default: return 8 // fallback pour 2 colonnes
        }
    }
    
    private var adaptiveDescriptionLineLimit: Int {
        switch numberOfColumns {
        case 2: return 8
        case 3: return 6
        case 4: return 6
        default: return 8 // fallback pour 2 colonnes
        }
    }
    
    private var adaptiveSpacing: CGFloat {
        switch numberOfColumns {
        case 2: return 8
        case 3: return 6
        case 4: return 4
        default: return 8 // fallback pour 2 colonnes
        }
    }
    
    private var adaptivePadding: CGFloat {
        switch numberOfColumns {
        case 2: return 16
        case 3: return 12
        case 4: return 8
        default: return 16 // fallback pour 2 colonnes
        }
    }
    
}