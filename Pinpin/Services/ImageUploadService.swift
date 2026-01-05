import Foundation
import UIKit

class ImageUploadService {
    static let shared = ImageUploadService()
    
    // Supabase Configuration
    private let projectURL = "https://ucbaswjuwwjgayehlfpl.supabase.co"
    private let bucketName = "images"
    // Using the anon key retrieved from project configuration
    private let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjYmFzd2p1d3dqZ2F5ZWhsZnBsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc1ODM0MjUsImV4cCI6MjA4MzE1OTQyNX0.eW5kDQkdOmTLMGiciu4FgjI29JV9YOGNLao1lnP1rps"
    
    private init() {}
    
    func uploadImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        // Run on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            // Resize image to max 800px to speed up upload/download
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
            
            // Log image size
            let imageSizeKB = Double(imageData.count) / 1024.0
            let dimensions = "\(Int(scaledImage.size.width))x\(Int(scaledImage.size.height))"
            print("📊 Image à uploader vers Supabase: \(String(format: "%.1f", imageSizeKB)) KB (\(dimensions))")
            
            // Generate unique filename
            let filename = "\(UUID().uuidString).jpg"
            
            // Supabase Storage URL: POST /storage/v1/object/{bucket}/{path}
            let urlString = "\(self.projectURL)/storage/v1/object/\(self.bucketName)/\(filename)"
            
            guard let url = URL(string: urlString) else {
                DispatchQueue.main.async {
                    completion(.failure(ImageUploadError.invalidURL))
                }
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(self.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
            request.httpBody = imageData
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ Erreur réseau Supabase: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if (200...299).contains(httpResponse.statusCode) {
                        // Success! Construct public URL
                        // Public URL format: {projectURL}/storage/v1/object/public/{bucket}/{path}
                        let publicURL = "\(self.projectURL)/storage/v1/object/public/\(self.bucketName)/\(filename)"
                        print("✅ Upload Supabase réussi: \(publicURL)")
                        DispatchQueue.main.async {
                            completion(.success(publicURL))
                        }
                    } else {
                        print("📡 Erreur HTTP Supabase: \(httpResponse.statusCode)")
                        if let data = data, let responseString = String(data: data, encoding: .utf8) {
                            print("📄 Réponse Supabase: \(responseString)")
                        }
                        DispatchQueue.main.async {
                            completion(.failure(ImageUploadError.serverError(code: httpResponse.statusCode)))
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(ImageUploadError.invalidResponse))
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
    case serverError(code: Int)
    
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
        case .serverError(let code):
            return "Server returned error code: \(code)"
        }
    }
}
