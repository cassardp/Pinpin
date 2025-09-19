//
//  ContentCardView.swift
//  Pinpin
//
//  Vue unifiée simple pour tous les types de contenu
//

import SwiftUI

struct ContentCardView: View {
    @ObservedObject var item: ContentItem
    
    var body: some View {
        if isTikTokContent {
            tiktokContentView
        } else if shouldUseSquareFormat {
            squareContentView
        } else {
            standardContentView
        }
    }
    
    // MARK: - Content Views
    
    private var tiktokContentView: some View {
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
    
    private var squareContentView: some View {
        VStack(alignment: .leading) {
            Rectangle()
                .aspectRatio(1.0, contentMode: .fit)
                .overlay(
                    SmartAsyncImage(item: item)
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                )
        }
    }
    
    private var standardContentView: some View {
        VStack(alignment: .leading) {
            SmartAsyncImage(item: item)
                .frame(maxWidth: .infinity)
                .aspectRatio(contentMode: .fit)
        }
    }
    
    // MARK: - Computed Properties
    
    private var isTikTokContent: Bool {
        guard let url = item.url else { return false }
        return url.contains("tiktok.com") || url.contains("vm.tiktok.com")
    }
    
    private var shouldUseSquareFormat: Bool {
        return item.contentTypeEnum == .books || item.contentTypeEnum == .music
    }
}
