//
//  TextDetailModal.swift
//  Pinpin
//
//  Modal view for displaying full text content
//

import SwiftUI

struct TextDetailModal: View {
    let item: ContentItem
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var editableText: String = ""
    @StateObject private var contentService = ContentServiceCoreData()
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                TextEditor(text: $editableText)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear {
                saveChanges()
                onSave()
            }
        }
        .onAppear {
            editableText = item.metadataDict["best_description"] ?? item.itemDescription ?? ""
        }
    }
    
    private func saveChanges() {
        item.itemDescription = editableText
        item.updatedAt = Date()
        contentService.updateContentItem(item)
    }
}

#Preview {
    TextDetailModal(item: ContentItem()) {
        // Preview callback
    }
}
