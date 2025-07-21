//
//  ShowContentView.swift
//  Neeed2
//
//  Specialized view for streaming show content type
//

import SwiftUI

struct ShowContentView: View {
    let item: ContentItem
    
    var body: some View {
        VStack(alignment: .leading) {
            SmartAsyncImage(item: item)
                .frame(maxWidth: .infinity)
                .aspectRatio(contentMode: .fit)
        }
    }
}

#Preview {
    ShowContentView(item: ContentItem())
        .padding()
}
