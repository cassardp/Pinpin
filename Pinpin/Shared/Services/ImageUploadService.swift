import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

actor ImageUploadService {
    static let shared = ImageUploadService()

    private let litterboxURL = URL(string: "https://litterbox.catbox.moe/resources/internals/api.php")!
    private let expirationTime = "1h" // Options: 1h, 12h, 24h, 72h

    private init() {}

    func uploadImage(_ image: PlatformImage) async throws -> String {
        // Resize image to max 800px
        let scaledImage = await resizeImage(image, maxDimension: 800)

        // Convert to JPEG
        guard let imageData = jpegData(from: scaledImage, quality: 0.7) else {
            throw ImageUploadError.invalidImage
        }

        let imageSizeKB = Double(imageData.count) / 1024.0
        let dimensions = "\(Int(scaledImage.size.width))x\(Int(scaledImage.size.height))"
        print("📊 Image à uploader vers Litterbox: \(String(format: "%.1f", imageSizeKB)) KB (\(dimensions))")

        // Build multipart request
        let boundary = UUID().uuidString
        var request = URLRequest(url: litterboxURL)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add reqtype field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"reqtype\"\r\n\r\n".data(using: .utf8)!)
        body.append("fileupload\r\n".data(using: .utf8)!)

        // Add time field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"time\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(expirationTime)\r\n".data(using: .utf8)!)

        // Add file
        let filename = "\(UUID().uuidString).jpg"
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"fileToUpload\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)

        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImageUploadError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            print("📡 Erreur HTTP Litterbox: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Réponse: \(responseString)")
            }
            throw ImageUploadError.serverError(code: httpResponse.statusCode)
        }

        guard let urlString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              urlString.hasPrefix("https://") else {
            print("📄 Réponse inattendue: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw ImageUploadError.invalidResponse
        }

        print("✅ Upload Litterbox réussi: \(urlString)")
        return urlString
    }

    // Legacy completion handler for compatibility
    nonisolated func uploadImage(_ image: PlatformImage, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                let url = try await self.uploadImage(image)
                await MainActor.run { completion(.success(url)) }
            } catch {
                await MainActor.run { completion(.failure(error)) }
            }
        }
    }

    private func resizeImage(_ image: PlatformImage, maxDimension: CGFloat) async -> PlatformImage {
        let size = image.size

        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }

        let scale = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        #if os(macOS)
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize),
                   from: NSRect(origin: .zero, size: size),
                   operation: .copy,
                   fraction: 1.0)
        newImage.unlockFocus()
        return newImage
        #else
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        #endif
    }

    private func jpegData(from image: PlatformImage, quality: CGFloat) -> Data? {
        #if os(macOS)
        guard let tiffRepresentation = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else {
            return nil
        }
        return bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: quality])
        #else
        return image.jpegData(compressionQuality: quality)
        #endif
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
