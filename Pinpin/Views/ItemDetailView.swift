//
//  ItemDetailView.swift
//  Pinpin
//
//  Vue détaillée d'un item avec transition hero iOS 18
//

import SwiftUI

struct ItemDetailView: View {
    let item: ContentItem
    let namespace: Namespace.ID
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    // Interactive pull-to-dismiss visuals
    @State private var scaleFactor: CGFloat = 1
    @State private var cornerRadius: CGFloat = 16
    @State private var chromeOpacity: CGFloat = 1
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Image principale
                SmartAsyncImage(item: item)
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                
                // Contenu principal
                VStack(alignment: .leading, spacing: 16) {
                    // Titre
                    Text(item.bestTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    // Description
                    if let desc = item.itemDescription, !desc.isEmpty {
                        Text(desc)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Métadonnées
                    VStack(alignment: .leading, spacing: 12) {
                        // Catégorie
                        if let categoryName = item.category?.name, !categoryName.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "folder.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(categoryName)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                            }
                        }
                        
                        // Domaine
                        if let urlString = item.url, let domain = domain(from: urlString) {
                            HStack(spacing: 8) {
                                Image(systemName: "link")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Button {
                                    if let url = URL(string: urlString) {
                                        openURL(url)
                                    }
                                } label: {
                                    Text(domain)
                                        .font(.subheadline)
                                        .foregroundStyle(.blue)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        // Date
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(item.createdAt, format: .dateTime.year().month().day())
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 4)
                    
                    // Bouton d'action principal
                    if let urlString = item.url, !urlString.isEmpty {
                        Button {
                            if let url = URL(string: urlString) {
                                openURL(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "safari")
                                Text("Open")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .scaleEffect(scaleFactor)
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden()
        .background(Color(.systemBackground))
        .scrollIndicators(scaleFactor < 1 ? .hidden : .automatic, axes: .vertical)
        // Track vertical offset to drive scale/corner/opacity
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y
        } action: { _, newValue in
            if newValue >= 0 {
                // Normal
                scaleFactor = 1
                cornerRadius = 16
                chromeOpacity = 1
            } else {
                // Pulled down
                // Clamp factors to keep things reasonable
                let pull = min(max(-newValue, 0), 100)
                scaleFactor = max(0.85, 1 - (0.1 * (pull / 50)))
                cornerRadius = max(16, 55 - (35 / 50 * pull))
                chromeOpacity = max(0, 1 - (pull / 50))
            }
        }
        // Auto-dismiss when pulled beyond a threshold
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y < -50
        } action: { _, isTornOff in
            if isTornOff {
                dismiss()
            }
        }
    }

    // MARK: - Helpers
    private func domain(from urlString: String) -> String? {
        guard let url = URL(string: urlString), let host = url.host else { return nil }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
}
