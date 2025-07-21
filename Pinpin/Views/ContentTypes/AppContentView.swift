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
            SmartAsyncImage(item: item)
                .frame(maxWidth: .infinity)
                .aspectRatio(contentMode: .fit)
        }
    }
}
