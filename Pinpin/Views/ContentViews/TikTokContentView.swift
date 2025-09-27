//
//  TikTokContentView.swift
//  Pinpin
//
//  Vue spécialisée pour le contenu TikTok (format vertical 9:16)
//

import SwiftUI

struct TikTokContentView: View {
    let item: ContentItem
    
    var body: some View {
        VStack(alignment: .leading) {
            Rectangle()
                .aspectRatio(9/16, contentMode: .fit)
                .overlay(
                    SmartAsyncImage(item: item)
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                )
        }
    }
}
