//
//  AppContentView.swift
//  Neeed2
//
//  Specialized view for app content type
//

import SwiftUI

struct AppContentView: View {
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
