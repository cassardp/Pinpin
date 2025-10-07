import Foundation
import SwiftUI
import UIKit
import SafariServices

// KISS: regroupe la logique de "Search Similar" (upload + URL Lens + warm-up + présentation)
final class SimilarSearchService {
    // Capsule de chargement (UI minimale, anglaise comme le reste du code)
    private static var loadingCapsule: UIView?
    
    // API publique
    static func searchSimilarProducts(for item: ContentItem, query: String?) {
        // Extraire l'image
        loadImage(from: item) { image in
            guard let image = image else {
                print("❌ Impossible de charger l'image pour la recherche")
                return
            }
            // Afficher la capsule de chargement
            showLoadingCapsule()
            
            // Upload via ImageUploadService existant
            ImageUploadService.shared.uploadImage(image) { result in
                switch result {
                case .success(let imageURL):
                    openGoogleLens(with: imageURL, query: query, originalSize: image.size)
                case .failure(let error):
                    print("❌ Erreur upload ImgBB: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        hideLoadingCapsule()
                    }
                }
            }
        }
    }
    
    // MARK: - Internals
    private static func loadImage(from item: ContentItem, completion: @escaping (UIImage?) -> Void) {
        if let imageData = item.imageData, let image = UIImage(data: imageData) {
            completion(image)
            return
        }
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
    
    private static func openGoogleLens(with imageURL: String, query: String?, originalSize: CGSize) {
        let startTime = Date()
        // Adapter la preview Uploadcare au ratio d'origine (pas de déformation)
        // On borne le côté le plus long à 800 px
        let maxLongSide: CGFloat = 800
        let w = max(originalSize.width, 1)
        let h = max(originalSize.height, 1)
        let targetW: Int
        let targetH: Int
        if w >= h {
            targetW = Int(maxLongSide)
            targetH = Int(round(maxLongSide * (h / w)))
        } else {
            targetH = Int(maxLongSide)
            targetW = Int(round(maxLongSide * (w / h)))
        }
        let previewURL = makeUploadcarePreviewURL(from: imageURL, width: max(targetW, 1), height: max(targetH, 1))
        let encodedImageURL = previewURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        var googleLensURL = "https://lens.google.com/upload?url=\(encodedImageURL)"
        
        if let query = query, !query.isEmpty {
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            googleLensURL += "&q=\(encodedQuery)"
            print("🗜️ Uploadcare preview URL: \(previewURL)")
            print("📝 Query de recherche: \(query)")
        } else {
            print("🗜️ Uploadcare preview URL: \(previewURL)")
            print("📝 Sans query spécifique (All)")
        }
        
        let urlBuildTime = Date().timeIntervalSince(startTime)
        print("⏱️ Construction URL: \(String(format: "%.3f", urlBuildTime))s")
        print("🔗 Google Lens URL: \(googleLensURL)")
        
        guard let url = URL(string: googleLensURL) else {
            print("❌ URL Google Lens invalide")
            return
        }
        
        print("🚀 Tentative d'ouverture de Google Lens avec SFSafariViewController...")
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                let safariVC = SFSafariViewController(url: url)
                
                if UIDevice.current.userInterfaceIdiom == .pad {
                    safariVC.modalPresentationStyle = .formSheet
                    safariVC.preferredContentSize = CGSize(width: 900, height: 1200)
                } else {
                    safariVC.modalPresentationStyle = .pageSheet
                }
                
                if #available(iOS 16.0, *) {
                    if let sheet = safariVC.sheetPresentationController {
                        sheet.detents = [.medium(), .large()]
                        sheet.selectedDetentIdentifier = .large
                        sheet.prefersGrabberVisible = true
                        sheet.prefersScrollingExpandsWhenScrolledToEdge = true
                        sheet.preferredCornerRadius = 16
                    }
                }
                
                var topController = rootViewController
                while let presented = topController.presentedViewController {
                    topController = presented
                }
                let presentTime = Date()
                topController.present(safariVC, animated: true) {
                    let totalTime = Date().timeIntervalSince(startTime)
                    let presentDuration = Date().timeIntervalSince(presentTime)
                    print("✅ Safari View Controller présenté avec succès")
                    print("⏱️ Temps présentation Safari: \(String(format: "%.3f", presentDuration))s")
                    print("⏱️ Temps total (construction + présentation): \(String(format: "%.3f", totalTime))s")
                    hideLoadingCapsule()
                }
            } else {
                print("❌ Impossible de trouver le view controller")
            }
        }
    }

    // Construit une URL Uploadcare avec transformation preview WxH
    private static func makeUploadcarePreviewURL(from base: String, width: Int, height: Int) -> String {
        // Formats attendus: https://ucarecdn.com/<uuid>/[...]
        // On insère "-/preview/WxH/" en suffixe (si déjà présent, on remplace)
        guard var components = URLComponents(string: base) else { return base }
        var path = components.path
        if path.hasSuffix("/") == false { path += "/" }
        // Supprimer une ancienne preview éventuelle simple (best-effort, KISS)
        if path.contains("-/preview/") {
            if let range = path.range(of: "-/preview/") {
                path = String(path[..<range.lowerBound])
            }
        }
        path += "-/preview/\(width)x\(height)/"
        components.path = path
        return components.string ?? base
    }
    
    private static func showLoadingCapsule() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        let capsule = UIView()
        capsule.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        capsule.layer.cornerRadius = 20
        capsule.translatesAutoresizingMaskIntoConstraints = false
        let label = UILabel()
        label.text = "Please wait..."
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        capsule.addSubview(label)
        window.addSubview(capsule)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: capsule.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: capsule.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: capsule.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: capsule.trailingAnchor, constant: -20),
            capsule.centerXAnchor.constraint(equalTo: window.centerXAnchor),
            capsule.centerYAnchor.constraint(equalTo: window.centerYAnchor),
            capsule.heightAnchor.constraint(equalToConstant: 50)
        ])
        capsule.alpha = 0
        UIView.animate(withDuration: 0.3) { capsule.alpha = 1 }
        loadingCapsule = capsule
    }
    
    private static func hideLoadingCapsule() {
        guard let capsule = loadingCapsule else { return }
        UIView.animate(withDuration: 0.3, animations: { capsule.alpha = 0 }) { _ in
            capsule.removeFromSuperview()
            loadingCapsule = nil
        }
    }
}
