//
//  TextDetailModal.swift
//  Pinpin
//
//  Modal view for displaying full text content
//

import SwiftUI

struct TextDetailModal: View {
    let text: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(text)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .textSelection(.enabled)
                        .padding()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TextDetailModal(text: "Exemple de texte long qui sera affiché dans la modal...")
}
