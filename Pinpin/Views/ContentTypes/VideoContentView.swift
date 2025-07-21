//
//  VideoContentView.swift
//  Neeed2
//
//  Specialized view for video content type
//

import SwiftUI

struct VideoContentView: View {
    let item: ContentItem
    
    var body: some View {
        VStack(alignment: .leading) {
            SmartAsyncImage(item: item)
                .frame(maxWidth: .infinity)
                .aspectRatio(contentMode: .fit)
        }
    }
}
