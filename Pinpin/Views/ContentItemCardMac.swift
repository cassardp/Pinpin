#if os(macOS)
import SwiftUI
import AppKit

struct ContentItemCardMac: View {
    @ObservedObject var item: ContentItem
    @StateObject private var userPreferences = UserPreferences.shared
    let cornerRadius: CGFloat
    let numberOfColumns: Int
    let isSelectionMode: Bool
    let onSelectionTap: (() -> Void)?
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Vue unifiée pour toutes les catégories
            ContentCardView(item: item)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .compositingGroup()
            .clipped()
            
            // URL en overlay dans le coin bas gauche
            if userPreferences.showURLs, let url = item.url, !url.isEmpty {
                Text(shortenURL(url))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary.opacity(0.7))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 4))
                    .padding(8)
                    .onTapGesture {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(url, forType: .string)
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.8)).combined(with: .move(edge: .bottom)),
                        removal: .opacity.combined(with: .scale(scale: 0.8))
                    ))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: cornerRadius)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: userPreferences.showURLs)
        .onTapGesture {
            if isSelectionMode {
                onSelectionTap?()
            } else if let urlString = item.url {
                handleContentTap(urlString: urlString)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    private func handleContentTap(urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// Raccourcit une URL pour afficher seulement le domaine principal
    private func shortenURL(_ urlString: String) -> String {
        // Cas spécial pour les URLs locales
        if urlString.hasPrefix("file:///") {
            return "Local"
        }
        
        guard let url = URL(string: urlString),
              let host = url.host else {
            return urlString
        }
        
        let cleanHost = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        
        return cleanHost
    }
}
#endif
