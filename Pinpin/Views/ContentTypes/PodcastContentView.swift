//
//  PodcastContentView.swift
//  Neeed2
//
//  Specialized view for podcast content type
//

import SwiftUI

struct PodcastContentView: View {
    let item: ContentItem
    
    var body: some View {
        VStack(alignment: .leading) {
            SmartAsyncImage(item: item)
                .frame(maxWidth: .infinity)
                .aspectRatio(contentMode: .fit)
        }
    }
}
