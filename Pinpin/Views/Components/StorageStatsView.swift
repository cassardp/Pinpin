//
//  StorageStatsView.swift
//  Pinpin
//
//  Vue pour afficher les statistiques de stockage des images
//

import SwiftUI
import CoreData

struct StorageStatsView: View {
    @State private var imageCount: Int = 0
    @State private var totalSize: Int64 = 0
    @State private var isLoading: Bool = true
    
    // Paramètres pour le filtrage
    let selectedContentType: String?
    let filteredItems: [ContentItem]
    
    var body: some View {
        HStack {

            Spacer()
            
            if isLoading {
                Text("CALCUL EN COURS...")
                    .font(.caption)
                    .foregroundColor(Color(UIColor.systemGray3))
            } else {
                // Affichage des stats de stockage pour tous les cas
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
                Text("\(imageCount) PIN\(imageCount > 1 ? "S" : "") • \(SharedImageService.shared.formatFileSize(totalSize).uppercased()) • V\(version) (\(build))")
                    .font(.footnote)
                    .foregroundColor(Color(UIColor.systemGray3))
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .onAppear {
            loadStorageStats()
        }
        .onChange(of: selectedContentType) { oldValue, newValue in
            // Recharger les stats quand le type change
            loadStorageStats()
        }
        .onChange(of: filteredItems.count) { oldValue, newValue in
            // Recharger les stats quand le nombre d'items filtrés change
            loadStorageStats()
        }
        .onChange(of: filteredItems.map { $0.safeId }) { oldValue, newValue in
            // Recharger les stats si la composition change mais pas le nombre
            loadStorageStats()
        }
    }
    
    private func loadStorageStats() {
        Task {
            // Compter tous les items filtrés (pas seulement ceux avec images)
            let totalItemCount = filteredItems.count
            
            // Calculer la taille des images uniquement
            let imageStats: (imageCount: Int, totalSize: Int64) =
                SharedImageService.shared.getStorageStatsForItems(filteredItems)
            
            await MainActor.run {
                self.imageCount = totalItemCount  // Tous les items, pas seulement ceux avec images
                self.totalSize = imageStats.totalSize  // Taille des images seulement
                self.isLoading = false
            }
        }
    }
    
    /// Méthode publique pour recharger les statistiques
    func refresh() {
        isLoading = true
        loadStorageStats()
    }
}

#Preview {
    StorageStatsView(selectedContentType: nil, filteredItems: [])
}
