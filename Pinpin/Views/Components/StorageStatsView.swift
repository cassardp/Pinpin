//
//  StorageStatsView.swift
//  Pinpin
//
//  Vue pour afficher les statistiques de stockage des images
//

import SwiftUI

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
                    .font(.system(size: 12))
                    .foregroundColor(.gray.opacity(0.5))
            } else {
                // Affichage des stats de stockage pour tous les cas
                Text("\(imageCount) PIN\(imageCount > 1 ? "S" : "") • \(formatFileSize(totalSize).uppercased())")
                    .font(.system(size: 12))
                    .foregroundColor(.gray.opacity(0.5))
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
            // Compter tous les items filtrés
            let totalItemCount = filteredItems.count
            
            // Calculer la taille des images SwiftData
            var imageCount = 0
            var totalSize: Int64 = 0
            
            for item in filteredItems {
                if let imageData = item.imageData {
                    imageCount += 1
                    totalSize += Int64(imageData.count)
                }
            }
            
            await MainActor.run {
                self.imageCount = totalItemCount  // Tous les items
                self.totalSize = totalSize  // Taille totale des images SwiftData
                self.isLoading = false
            }
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        
        let formattedString = formatter.string(fromByteCount: bytes)
        return formattedString.replacingOccurrences(of: ",", with: ".")
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
