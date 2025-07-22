//
//  TextContentView.swift
//  Neeed2
//
//  Specialized view for text content type
//

import SwiftUI

struct TextContentView: View {
    let item: ContentItem
    @State private var showingTextModal = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {



                    
            // Description - utiliser la meilleure disponible
            let bestDescription = item.metadataDict["best_description"] ?? item.itemDescription
            if let description = bestDescription, !description.isEmpty {
                Text(description)
                    .font(.body)
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
