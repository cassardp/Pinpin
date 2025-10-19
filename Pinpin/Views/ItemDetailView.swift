//
//  ItemDetailView.swift
//  Pinpin
//
//  Vue détaillée d'un item avec transition hero iOS 18
//

import SwiftUI
import SwiftData

struct ItemDetailView: View {
    let item: ContentItem
    let namespace: Namespace.ID
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.sortOrder, order: .forward)
    private var allCategories: [Category]
    
    // Interactive pull-to-dismiss visuals
    @State private var scaleFactor: CGFloat = 1
    @State private var cornerRadius: CGFloat = 32
    @State private var chromeOpacity: CGFloat = 1
    
    // États pour les actions
    @State private var showShareSheet = false
    @State private var showAddCategory = false
    @State private var newCategoryName = ""
    @State private var categoryMenuTrigger = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Image principale (tap pour ouvrir)
                Button {
                    openItem()
                } label: {
                    SmartAsyncImage(item: item)
                        .aspectRatio(contentMode: .fit)
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: cornerRadius,
                                bottomLeadingRadius: 16,
                                bottomTrailingRadius: 16,
                                topTrailingRadius: cornerRadius
                            )
                        )
                        .overlay(
                            UnevenRoundedRectangle(
                                topLeadingRadius: cornerRadius,
                                bottomLeadingRadius: 16,
                                bottomTrailingRadius: 16,
                                topTrailingRadius: cornerRadius
                            )
                            .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Barre d'actions moderne
                HStack(spacing: 0) {
                    // Changer de catégorie (menu contextuel ou sheet d'ajout)
                    let categoryNames = allCategories.map { $0.name }
                    
                    if categoryNames.count <= 1 {
                        // S'il n'y a qu'une seule catégorie, ouvrir la sheet d'ajout
                        Button {
                            categoryMenuTrigger += 1
                            showAddCategory = true
                        } label: {
                            ActionButtonLabel(
                                icon: "folder",
                                label: item.safeCategoryName
                            )
                        }
                        .buttonStyle(.plain)
                        .sensoryFeedback(.impact(weight: .light), trigger: categoryMenuTrigger)
                    } else {
                        // Sinon, afficher le menu normal
                        Menu {
                            ForEach(categoryNames, id: \.self) { categoryName in
                                if categoryName != item.safeCategoryName {
                                    Button(action: {
                                        changeCategory(to: categoryName)
                                    }) {
                                        Label(categoryName, systemImage: "folder")
                                    }
                                }
                            }
                        } label: {
                            ActionButtonLabel(
                                icon: "folder",
                                label: item.safeCategoryName
                            )
                        }
                        .buttonStyle(.plain)
                        .sensoryFeedback(.impact(weight: .light), trigger: categoryMenuTrigger)
                        .simultaneousGesture(TapGesture().onEnded {
                            categoryMenuTrigger += 1
                        })
                    }
                    
                    Divider()
                        .frame(height: 32)
                        .padding(.horizontal, 8)
                    
                    // Recherche similaire
                    ActionButton(
                        icon: "binoculars",
                        label: "Similar"
                    ) {
                        SimilarSearchService.searchSimilarProducts(for: item, query: nil)
                    }
                    
                    Divider()
                        .frame(height: 32)
                        .padding(.horizontal, 8)
                    
                    // Partager
                    ActionButton(
                        icon: "square.and.arrow.up",
                        label: "Share"
                    ) {
                        showShareSheet = true
                    }
                    
                    Divider()
                        .frame(height: 32)
                        .padding(.horizontal, 8)
                    
                    // Ouvrir dans Safari
                    ActionButton(
                        icon: "arrow.up.right",
                        label: "Open"
                    ) {
                        openItem()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.systemGray3), lineWidth: 0.5)
                )
                .padding(.horizontal, 16)
                
                Spacer()
                    .frame(height: 20)
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .scaleEffect(scaleFactor)
        }
        .sheet(isPresented: $showShareSheet) {
            if let urlString = item.url,
               !urlString.isEmpty,
               let url = URL(string: urlString) {
                ActivityViewController(activityItems: [url])
            }
        }
        .sheet(isPresented: $showAddCategory) {
            RenameCategorySheet(
                name: $newCategoryName,
                onCancel: {
                    showAddCategory = false
                    newCategoryName = ""
                },
                onSave: {
                    let trimmedName = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedName.isEmpty {
                        let newCategory = Category(name: trimmedName)
                        modelContext.insert(newCategory)
                        try? modelContext.save()
                        changeCategory(to: trimmedName)
                        newCategoryName = ""
                        showAddCategory = false
                    }
                }
            )
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
                cornerRadius = 32
                chromeOpacity = 1
            } else {
                // Pulled down
                // Clamp factors to keep things reasonable
                let pull = min(max(-newValue, 0), 100)
                scaleFactor = max(0.85, 1 - (0.1 * (pull / 50)))
                cornerRadius = max(32, 55 - (23 / 50 * pull))
                chromeOpacity = max(0, 1 - (pull / 50))
            }
        }
        // Auto-dismiss when pulled beyond a threshold
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y < -30
        } action: { _, isTornOff in
            if isTornOff {
                dismiss()
            }
        }
    }

    // MARK: - Actions
    
    private func openItem() {
        guard let urlString = item.url,
              !urlString.isEmpty,
              let url = URL(string: urlString) else { return }
        openURL(url)
    }
    
    private func changeCategory(to category: String) {
        guard let targetCategory = allCategories.first(where: { $0.name == category }) else { return }
        item.category = targetCategory
        try? modelContext.save()
    }
}

// MARK: - Action Button Components

private struct ActionButton: View {
    let icon: String
    let label: String
    var color: Color = .primary
    let action: () -> Void
    
    @State private var triggerFeedback = 0
    
    var body: some View {
        Button(action: {
            triggerFeedback += 1
            action()
        }) {
            ActionButtonLabel(icon: icon, label: label, color: color)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: triggerFeedback)
    }
}

private struct ActionButtonLabel: View {
    let icon: String
    let label: String
    var color: Color = .primary
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(color)
                .frame(height: 20)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(height: 16)
        }
        .frame(maxWidth: .infinity)
    }
}

// Wrapper pour UIActivityViewController
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
