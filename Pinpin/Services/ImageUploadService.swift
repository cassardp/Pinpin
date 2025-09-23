import Foundation
import UIKit

class ImageUploadService {
    static let shared = ImageUploadService()
    
    private let apiKey = "b433c3f69127777287573e89109836bc"
    private let uploadURL = "https://api.imgbb.com/1/upload"
    
    private init() {}
    
    func uploadImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(ImageUploadError.invalidImage))
            return
        }
        
        // ImgBB utilise base64 dans le form data
        let base64String = imageData.base64EncodedString()
        
        // URL avec paramètres
        let urlString = "\(uploadURL)?expiration=600&key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            completion(.failure(ImageUploadError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add image data (base64 pour ImgBB)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"\r\n\r\n".data(using: .utf8)!)
        body.append(base64String.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Erreur réseau ImgBB: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Réponse HTTP ImgBB: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("❌ Aucune donnée reçue d'ImgBB")
                DispatchQueue.main.async {
                    completion(.failure(ImageUploadError.noData))
                }
                return
            }
            
            // Debug: afficher la réponse brute
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Réponse ImgBB: \(responseString)")
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let success = json["success"] as? Bool, success,
                       let dataDict = json["data"] as? [String: Any],
                       let url = dataDict["url"] as? String {
                        print("✅ Upload ImgBB réussi: \(url)")
                        DispatchQueue.main.async {
                            completion(.success(url))
                        }
                    } else {
                        print("❌ Réponse ImgBB invalide ou échec")
                        DispatchQueue.main.async {
                            completion(.failure(ImageUploadError.invalidResponse))
                        }
                    }
                } else {
                    print("❌ JSON ImgBB invalide")
                    DispatchQueue.main.async {
                        completion(.failure(ImageUploadError.invalidResponse))
                    }
                }
            } catch {
                print("❌ Erreur parsing JSON ImgBB: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
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
