//
//  TextOnlyContentView.swift
//  Pinpin
//
//  Vue spécialisée pour le contenu texte uniquement (sans image)
//

import SwiftUI

struct TextOnlyContentView: View {
    let item: ContentItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Titre principal
            Text(item.bestTitle)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(10)
            
            // Description si disponible et différente du titre
            if let description = item.itemDescription, 
               !description.isEmpty,
               description != item.title {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(10)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
}