import Foundation
import UIKit

class ImageUploadService {
    static let shared = ImageUploadService()
    
    // Uploadcare public key (provided by user)
    private let uploadcarePublicKey = "f43283317c792cb79050"
    private let uploadURL = "https://upload.uploadcare.com/base/"
    
    private init() {}
    
    func uploadImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        // Déplacer tout le traitement sur un thread background
        DispatchQueue.global(qos: .userInitiated).async {
            // Downscale l'image pour accélérer l'upload ET le téléchargement par Google
            let maxDimension: CGFloat = 800
            let scaledImage: UIImage
            
            if image.size.width > maxDimension || image.size.height > maxDimension {
                let scale = min(maxDimension / image.size.width, maxDimension / image.size.height)
                let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
                
                UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                image.draw(in: CGRect(origin: .zero, size: newSize))
                scaledImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
                UIGraphicsEndImageContext()
            } else {
                scaledImage = image
            }
            
            guard let imageData = scaledImage.jpegData(compressionQuality: 0.7) else {
                DispatchQueue.main.async {
                    completion(.failure(ImageUploadError.invalidImage))
                }
                return
            }
            
            // Log de la taille de l'image
            let imageSizeKB = Double(imageData.count) / 1024.0
            let imageSizeMB = imageSizeKB / 1024.0
            let dimensions = "\(Int(scaledImage.size.width))x\(Int(scaledImage.size.height))"
            
            if imageSizeMB >= 1.0 {
                print("📊 Image à uploader: \(String(format: "%.2f", imageSizeMB)) MB (\(dimensions))")
            } else {
                print("📊 Image à uploader: \(String(format: "%.1f", imageSizeKB)) KB (\(dimensions))")
            }
            
            // Uploadcare: multipart direct binaire
            guard let url = URL(string: self.uploadURL) else {
                DispatchQueue.main.async {
                    completion(.failure(ImageUploadError.invalidURL))
                }
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            var body = Data()
            
            // UPLOADCARE_PUB_KEY
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"UPLOADCARE_PUB_KEY\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(self.uploadcarePublicKey)".data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)

            // UPLOADCARE_STORE=0 (ne pas stocker en permanence)
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"UPLOADCARE_STORE\"\r\n\r\n".data(using: .utf8)!)
            body.append("0".data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)

            // file (binary JPEG)
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            
            request.httpBody = body
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ Erreur réseau Uploadcare: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 Réponse HTTP Uploadcare: \(httpResponse.statusCode)")
                }
                
                guard let data = data else {
                    print("❌ Aucune donnée reçue d'Uploadcare")
                    DispatchQueue.main.async {
                        completion(.failure(ImageUploadError.noData))
                    }
                    return
                }
                
                // Debug: afficher la réponse brute
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Réponse Uploadcare: \(responseString)")
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let uuid = json["file"] as? String, !uuid.isEmpty {
                            let cdnURL = "https://ucarecdn.com/\(uuid)/"
                            print("✅ Upload Uploadcare réussi: \(cdnURL)")
                            DispatchQueue.main.async {
                                completion(.success(cdnURL))
                            }
                        } else {
                            print("❌ Réponse Uploadcare invalide ou échec")
                            DispatchQueue.main.async {
                                completion(.failure(ImageUploadError.invalidResponse))
                            }
                        }
                    } else {
                        print("❌ JSON Uploadcare invalide")
                        DispatchQueue.main.async {
                            completion(.failure(ImageUploadError.invalidResponse))
                        }
                    }
                } catch {
                    print("❌ Erreur parsing JSON Uploadcare: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }.resume()
        }
    }
}

enum ImageUploadError: Error, LocalizedError {
    case invalidImage
    case invalidURL
    case noData
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Unable to convert image to data"
        case .invalidURL:
            return "Invalid upload URL"
        case .noData:
            return "No data received from server"
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}
