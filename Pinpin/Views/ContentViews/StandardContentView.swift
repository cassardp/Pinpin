//
//  StandardContentView.swift
//  Pinpin
//
//  Vue spécialisée pour le contenu standard (format adaptatif)
//

import SwiftUI

struct StandardContentView: View {
    let item: ContentItem
    
    var body: some View {
        VStack(alignment: .leading) {
            SmartAsyncImage(item: item)
                .frame(maxWidth: .infinity)
                .aspectRatio(contentMode: .fit)
        }
    }
}
