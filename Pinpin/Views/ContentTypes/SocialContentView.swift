//
//  SocialContentView.swift
//  Neeed2
//
//  Specialized view for social media content type
//

import SwiftUI

struct SocialContentView: View {
    let item: ContentItem
    
    private var isTikTokContent: Bool {
        guard let url = item.url else { return false }
        let urlString = url.lowercased()
        return urlString.contains("tiktok.com") || urlString.contains("vm.tiktok.com") || urlString.contains("m.tiktok.com")
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if isTikTokContent {
                Rectangle()
                    .aspectRatio(9/16, contentMode: .fit)
                    .overlay(
                        SmartAsyncImage(item: item)
                            .aspectRatio(contentMode: .fill)
                            .clipped()
                    )
            } else {
                SmartAsyncImage(item: item)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(contentMode: .fit)
            }
        }
    }
}
