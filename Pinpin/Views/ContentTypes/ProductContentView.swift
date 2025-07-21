//
//  ProductContentView.swift
//  Neeed2
//
//  Specialized view for product content type
//

import SwiftUI

struct ProductContentView: View {
    let item: ContentItem
    
    var body: some View {
        VStack(alignment: .leading) {
            SmartAsyncImage(item: item)
                .frame(maxWidth: .infinity)
                .aspectRatio(contentMode: .fit)
        }
    }
}
