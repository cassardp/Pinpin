import SwiftUI
import SwiftData
import UIKit

struct ContentItemContextMenu: View {
    let item: ContentItem
    let dataService: DataService
    let onStorageStatsRefresh: () -> Void
    let onDeleteRequest: () -> Void
    
    // Initialisation directe des catégories pour éviter le délai d'affichage
    private var categoryNames: [String] {
        dataService.fetchCategoryNames()
    }
    
    var body: some View {
        VStack {
            // Share
            if let url = item.url, !url.hasPrefix("file://") {
                Button(action: {
                    shareContent()
                }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
            
            // Category menu
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
                Label(item.safeCategoryName.capitalized, systemImage: "folder")
            }
            
            // Search Similar
            Button(action: {
                searchSimilarProducts()
            }) {
                Label("Search Similar", systemImage: "binoculars")
            }
            
            Divider()
            
            // Delete
            Button(role: .destructive, action: {
                onDeleteRequest()
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Actions
    
    private func shareContent() {
        guard let url = item.url, let shareURL = URL(string: url) else { return }
        
        let activityViewController = UIActivityViewController(
            activityItems: [shareURL],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityViewController, animated: true)
        }
    }
    
    private func changeCategory(to category: String) {
        dataService.updateContentItem(item, categoryName: category)
        onStorageStatsRefresh()
    }
    
    private func searchSimilarProducts() {
        // Extraire l'image du ContentItem
        loadImageFromItem { image in
            guard let image = image else {
                print("❌ Impossible de charger l'image pour la recherche")
                return
            }
            
            // Afficher la capsule de chargement
            Self.showLoadingCapsule()
            
            // Upload vers ImgBB
            ImageUploadService.shared.uploadImage(image) { result in
                // Fermer la capsule de chargement
                DispatchQueue.main.async {
                    Self.hideLoadingCapsule()
                }
                
                switch result {
                case .success(let imageURL):
                    // Ouvrir Google Lens avec l'URL de l'image
                    Self.openGoogleLens(with: imageURL)
                case .failure(let error):
                    print("❌ Erreur upload ImgBB: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func loadImageFromItem(completion: @escaping (UIImage?) -> Void) {
        // Vérifier d'abord si on a une image locale
        if let thumbnailUrl = item.thumbnailUrl, !thumbnailUrl.isEmpty, thumbnailUrl.hasPrefix("images/") {
            if let localURL = SharedImageService.shared.getImageURL(from: thumbnailUrl) as URL?,
               FileManager.default.fileExists(atPath: localURL.path),
               let imageData = try? Data(contentsOf: localURL),
               let image = UIImage(data: imageData) {
                completion(image)
                return
            }
        }
        
        // Sinon, essayer de charger depuis l'URL distante
        if let thumbnailUrl = item.thumbnailUrl, !thumbnailUrl.isEmpty, !thumbnailUrl.hasPrefix("images/"),
           let url = URL(string: thumbnailUrl) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                DispatchQueue.main.async {
                    if let data = data, let image = UIImage(data: data) {
                        completion(image)
                    } else {
                        completion(nil)
                    }
                }
            }.resume()
        } else {
            completion(nil)
        }
    }
    
    private static func openGoogleLens(with imageURL: String) {
        // URL Google Lens avec l'image uploadée
        let encodedImageURL = imageURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let googleLensURL = "https://lens.google.com/uploadbyurl?url=\(encodedImageURL)"
        
        print("🔍 Ouverture Google Lens avec URL: \(imageURL)")
        
        if let url = URL(string: googleLensURL) {
            UIApplication.shared.open(url)
        } else {
            print("❌ URL Google Lens invalide")
        }
    }
    
    private static var loadingCapsule: UIView?
    
    private static func showLoadingCapsule() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        // Créer la capsule
        let capsule = UIView()
        capsule.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        capsule.layer.cornerRadius = 20
        capsule.translatesAutoresizingMaskIntoConstraints = false
        
        // Label "Please wait..."
        let label = UILabel()
        label.text = "Please wait..."
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        capsule.addSubview(label)
        window.addSubview(capsule)
        
        // Contraintes
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: capsule.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: capsule.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: capsule.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: capsule.trailingAnchor, constant: -20),
            
            capsule.centerXAnchor.constraint(equalTo: window.centerXAnchor),
            capsule.centerYAnchor.constraint(equalTo: window.centerYAnchor),
            capsule.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Animation d'apparition
        capsule.alpha = 0
        UIView.animate(withDuration: 0.3) {
            capsule.alpha = 1
        }
        
        loadingCapsule = capsule
    }
    
    private static func hideLoadingCapsule() {
        guard let capsule = loadingCapsule else { return }
        
        UIView.animate(withDuration: 0.3, animations: {
            capsule.alpha = 0
        }) { _ in
            capsule.removeFromSuperview()
            loadingCapsule = nil
        }
    }
}
