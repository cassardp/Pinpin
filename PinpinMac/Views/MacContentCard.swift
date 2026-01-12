//
//  MacContentCard.swift
//  PinpinMac
//
//  Carte de contenu pour macOS avec effet hover
//

import SwiftUI

struct MacContentCard: View {
    let item: ContentItem
    let isHovered: Bool
    let onTap: () -> Void
    let onOpenURL: () -> Void
    
    @State private var imageFromData: NSImage?
    @State private var hasLoadedImage = false
    
    var body: some View {
        // Juste l'image, comme sur iPhone
        imageView
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(
                color: isHovered ? Color.black.opacity(0.2) : Color.black.opacity(0.08),
                radius: isHovered ? 16 : 6,
                y: isHovered ? 8 : 2
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
            .onTapGesture(count: 2) {
                onOpenURL()
            }
            .onTapGesture(count: 1) {
                onTap()
            }
            .onAppear {
                if !hasLoadedImage {
                    loadImageFromData()
                    hasLoadedImage = true
                }
            }
    }
    
    // MARK: - Image View
    
    @ViewBuilder
    private var imageView: some View {
        Group {
            if let nsImage = imageFromData {
                // Image stockée localement
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if let remoteURL = getRemoteURL() {
                // Image distante
                AsyncImage(url: remoteURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure(_):
                        placeholderView
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 150)
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                // Pas d'image - afficher un placeholder avec le titre
                linkPlaceholderView
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var placeholderView: some View {
        Rectangle()
            .fill(LinearGradient(
                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(height: 120)
            .overlay {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
            }
    }
    
    private var linkPlaceholderView: some View {
        VStack(spacing: 12) {
            Image(systemName: "globe")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            Text(item.bestTitle)
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .background(
            LinearGradient(
                colors: [Color.accentColor.opacity(0.1), Color.accentColor.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    // MARK: - Helpers
    
    private func loadImageFromData() {
        guard let imageData = item.imageData else { return }
        if let nsImage = NSImage(data: imageData) {
            self.imageFromData = nsImage
        }
    }
    
    private func getRemoteURL() -> URL? {
        if let thumbnailUrl = item.thumbnailUrl,
           !thumbnailUrl.isEmpty,
           !thumbnailUrl.hasPrefix("images/"),
           !thumbnailUrl.hasPrefix("file:///"),
           let url = URL(string: thumbnailUrl) {
            return url
        }
        return nil
    }
}
