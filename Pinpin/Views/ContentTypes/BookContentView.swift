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
            SmartAsyncImage(item: item)
                .frame(maxWidth: .infinity)
                .aspectRatio(contentMode: .fit)
        }
    }
}
