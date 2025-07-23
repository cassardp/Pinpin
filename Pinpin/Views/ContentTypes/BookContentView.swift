//
//  BookContentView.swift
//  Neeed2
//
//  Specialized view for book content type
//

import SwiftUI

struct BookContentView: View {
    let item: ContentItem
    
    var body: some View {
        VStack(alignment: .leading) {
            Rectangle()
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    SmartAsyncImage(item: item)
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                )
        }
    }
}
