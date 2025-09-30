//
//  ImageOptimizationService.swift
//  Pinpin
//
//  Service partagé pour l'optimisation des images
//

import UIKit

final class ImageOptimizationService {
    static let shared = ImageOptimizationService()
    
    private init() {}
    
    /// Optimise une image pour le stockage SwiftData
    /// - Parameters:
    ///   - image: L'image à optimiser
    ///   - maxSize: Taille maximale en pixels (défaut: 1024)
    ///   - maxBytes: Taille maximale en octets (défaut: 1MB)
    /// - Returns: Les données JPEG optimisées
    func optimize(
        _ image: UIImage,
        maxSize: CGFloat = AppConstants.maxImageSize,
        maxBytes: Int = AppConstants.maxImageBytes
    ) -> Data {
        var compressionQuality = AppConstants.defaultCompressionQuality
        var compressedData = image.jpegData(compressionQuality: compressionQuality) ?? Data()
        
        // Réduire la qualité jusqu'à obtenir moins de maxBytes
        while compressedData.count > maxBytes && compressionQuality > AppConstants.minimumCompressionQuality {
            compressionQuality -= 0.1
            compressedData = image.jpegData(compressionQuality: compressionQuality) ?? Data()
        }
        
        // Si toujours trop gros, redimensionner l'image
        if compressedData.count > maxBytes {
            if let resizedData = resizeImage(image, maxSize: maxSize) {
                compressedData = resizedData
            }
        }
        
        print("[ImageOptimization] Image optimisée: \(compressedData.count) bytes (qualité: \(compressionQuality))")
        return compressedData
    }
    
    /// Redimensionne une image
    private func resizeImage(_ image: UIImage, maxSize: CGFloat) -> Data? {
        let size = image.size
        let ratio = min(maxSize / size.width, maxSize / size.height)
        
        guard ratio < 1.0 else {
            return image.jpegData(compressionQuality: AppConstants.defaultCompressionQuality)
        }
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage?.jpegData(compressionQuality: AppConstants.defaultCompressionQuality)
    }
}
