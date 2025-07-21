//
//  ArticleContentView.swift
//  Neeed2
//
//  Specialized view for article content type
//

import SwiftUI

struct ArticleContentView: View {
    let item: ContentItem
    
    var body: some View {
        VStack(alignment: .leading) {
            SmartAsyncImage(item: item)
                .frame(maxWidth: .infinity)
                .aspectRatio(contentMode: .fit)
        }
    }
}
