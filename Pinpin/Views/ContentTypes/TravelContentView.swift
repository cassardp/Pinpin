//
//  TravelContentView.swift
//  Neeed2
//
//  Specialized view for travel content type
//

import SwiftUI

struct TravelContentView: View {
    let item: ContentItem
    
    var body: some View {
        VStack(alignment: .leading) {
            SmartAsyncImage(item: item)
                .frame(maxWidth: .infinity)
                .aspectRatio(contentMode: .fit)
        }
    }
}
