//
//  SocialContentView.swift
//  Neeed2
//
//  Specialized view for social media content type
//

import SwiftUI

struct SocialContentView: View {
    let item: ContentItem
    
    var body: some View {
        VStack(alignment: .leading) {
            SmartAsyncImage(item: item)
                .frame(maxWidth: .infinity)
                .aspectRatio(contentMode: .fit)
        }
    }
}
