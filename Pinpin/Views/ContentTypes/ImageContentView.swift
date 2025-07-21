//
//  ImageContentView.swift
//  Neeed2
//
//  Specialized view for image content type
//

import SwiftUI

struct ImageContentView: View {
    let item: ContentItem
    
    var body: some View {
        VStack(alignment: .leading) {
            SmartAsyncImage(item: item)
                .frame(maxWidth: .infinity)
                .aspectRatio(contentMode: .fit)
        }
    }
}
