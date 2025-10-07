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
            ZStack(alignment: .topLeading) {
                // Content (image en haut)
                VStack(spacing: 0) {
                    SmartAsyncImage(item: item)
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(Color(.separator), lineWidth: 0.5)
                        )
                        .padding(10)

                    // Details section
                    VStack(alignment: .leading, spacing: 8) {
                        // Title
                        Text(item.bestTitle)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        // Meta row: category + domain
                        HStack(spacing: 8) {
                            if let categoryName = item.category?.name, !categoryName.isEmpty {
                                Text(categoryName)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.secondarySystemBackground), in: Capsule())
                            }
                            if let urlString = item.url, let domain = domain(from: urlString) {
                                Button {
                                    if let url = URL(string: urlString) {
                                        openURL(url)
                                    }
                                } label: {
                                    Text(domain)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .underline(false)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Description if present
                        if let desc = item.itemDescription, !desc.isEmpty {
                            Text(desc)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        // Created date
                        Text(item.createdAt, format: .dateTime.year().month().day())
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    // All item data
                    VStack(alignment: .leading, spacing: 10) {
                        Divider().padding(.vertical, 4)
                        Text("All item data")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        // Basic fields
                        KeyValueRow(label: "ID", value: item.id.uuidString)
                        KeyValueRow(label: "Title", value: item.title)
                        if let desc = item.itemDescription, !desc.isEmpty {
                            KeyValueRow(label: "Description", value: desc)
                        }
                        if let url = item.url, !url.isEmpty {
                            KeyValueRow(label: "URL", value: url)
                        }
                        if let thumb = item.thumbnailUrl, !thumb.isEmpty {
                            KeyValueRow(label: "Thumbnail URL", value: thumb)
                        }
                        KeyValueRow(label: "Category", value: item.category?.name ?? "—")
                        KeyValueRow(label: "Hidden", value: item.isHidden ? "true" : "false")
                        if let userId = item.userId { KeyValueRow(label: "User ID", value: userId.uuidString) }
                        KeyValueRow(label: "Created", value: item.createdAt.formatted(date: .abbreviated, time: .shortened))
                        KeyValueRow(label: "Updated", value: item.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        if let data = item.imageData { KeyValueRow(label: "Image size", value: bytesString(data.count)) }

                        // Metadata dictionary
                        if !item.metadataDict.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Metadata (\(item.metadataDict.count) entries)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(item.metadataDict.keys.sorted(), id: \.self) { key in
                                        let value = item.metadataDict[key] ?? ""
                                        HStack(alignment: .top, spacing: 6) {
                                            Text(key + ":")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .frame(minWidth: 90, alignment: .leading)
                                            Text(value)
                                                .font(.caption)
                                                .foregroundStyle(.primary)
                                                .textSelection(.enabled)
                                                .lineLimit(nil)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                }
                                .padding(10)
                                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
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

    private func bytesString(_ count: Int) -> String {
        let kb = Double(count) / 1024.0
        if kb < 1024 {
            return String(format: "%.1f KB", kb)
        } else {
            let mb = kb / 1024.0
            return String(format: "%.2f MB", mb)
        }
    }
}

// MARK: - UI Helpers
private struct KeyValueRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label + ":")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(minWidth: 90, alignment: .leading)
            Text(value)
                .font(.caption)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
