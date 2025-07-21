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
            SmartAsyncImage(item: item)
                .frame(maxWidth: .infinity)
                .aspectRatio(contentMode: .fit)
        }
    }
}
