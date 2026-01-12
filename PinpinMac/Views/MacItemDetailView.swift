//
//  MacItemDetailView.swift
//  PinpinMac
//
//  Vue détaillée d'un item pour macOS
//

import SwiftUI
import SwiftData

struct MacItemDetailView: View {
    let item: ContentItem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.sortOrder, order: .forward)
    private var allCategories: [Category]
    
    @State private var imageFromData: NSImage?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header avec bouton fermer
            headerView
            
            Divider()
            
            // Contenu
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Image principale
                    imageSection
                    
                    // Informations
                    infoSection
                    
                    // Actions
                    actionsSection
                    
                    Spacer(minLength: 32)
                }
                .padding(32)
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            loadImage()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.bestTitle)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(item.safeCategoryName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    // MARK: - Image Section
    
    @ViewBuilder
    private var imageSection: some View {
        Group {
            if let nsImage = imageFromData {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
            } else if let remoteURL = getRemoteURL() {
                AsyncImage(url: remoteURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
                    case .failure(_):
                        noImagePlaceholder
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                    @unknown default:
                        noImagePlaceholder
                    }
                }
            } else {
                noImagePlaceholder
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var noImagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.accentColor.opacity(0.1))
            .frame(height: 200)
            .overlay {
                VStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                    
                    Text(item.bestTitle)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
    }
    
    // MARK: - Info Section
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Titre
            if !item.title.isEmpty && item.title != "Nouveau contenu" {
                infoRow(label: "Title", value: item.title)
            }
            
            // Description
            if let description = item.itemDescription, !description.isEmpty {
                infoRow(label: "Description", value: description)
            }
            
            // URL
            if let url = item.url, !url.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Link")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(url)
                        .font(.body)
                        .foregroundColor(.accentColor)
                        .lineLimit(2)
                        .onTapGesture {
                            if let validURL = URL(string: url) {
                                NSWorkspace.shared.open(validURL)
                            }
                        }
                }
            }
            
            // Date
            infoRow(label: "Created", value: formattedDate(item.createdAt))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
    
    private func infoRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.body)
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        HStack(spacing: 12) {
            // Ouvrir dans le navigateur
            if let url = item.url, let validURL = URL(string: url) {
                Button {
                    NSWorkspace.shared.open(validURL)
                } label: {
                    Label("Open in Browser", systemImage: "safari")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            
            // Copier le lien
            if let url = item.url {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(url, forType: .string)
                } label: {
                    Label("Copy Link", systemImage: "link")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            
            // Changer de catégorie
            Menu {
                ForEach(allCategories, id: \.id) { category in
                    if category.name != item.safeCategoryName {
                        Button(category.name) {
                            item.category = category
                            try? modelContext.save()
                        }
                    }
                }
            } label: {
                Label("Move to...", systemImage: "folder")
                    .frame(maxWidth: .infinity)
            }
            .menuStyle(.borderlessButton)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
        }
    }
    
    // MARK: - Helpers
    
    private func loadImage() {
        guard let imageData = item.imageData else { return }
        imageFromData = NSImage(data: imageData)
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
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
