//
//  MusicContentView.swift
//  Neeed2
//
//  Specialized view for music content type with platform-specific colors
//

import SwiftUI

struct MusicContentView: View {
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
