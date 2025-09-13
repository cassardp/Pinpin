//
//  StorageStatsView.swift
//  Neeed2
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
                    .foregroundColor(Color(UIColor.systemGray2))
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
    }
    
    private func loadStorageStats() {
        Task {
            let stats: (imageCount: Int, totalSize: Int64)
            
            if selectedContentType == nil {
                // Mode "Tout" : calculer les stats de stockage globales
                stats = SharedImageService.shared.getStorageStats()
            } else {
                // Mode filtré : calculer les stats pour les items filtrés
                stats = SharedImageService.shared.getStorageStatsForItems(filteredItems)
            }
            
            await MainActor.run {
                self.imageCount = stats.imageCount
                self.totalSize = stats.totalSize
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
