//
//  OCRService.swift
//  PinpinMacShareExtension
//
//  Service OCR pour extraire le texte des images avec Vision sur macOS
//

import Foundation
import Vision
import AppKit

class OCRService {
    static let shared = OCRService()
    private init() {}
    
    /// Extrait le texte d'une image en utilisant Vision OCR en mode accurate
    func extractText(from image: NSImage, completion: @escaping (String?) -> Void) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            completion(nil)
            return
        }
        
        let request = VNRecognizeTextRequest { (request, error) in
            if let error = error {
                print("[OCRService] Erreur OCR: \(error)")
                completion(nil)
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(nil)
                return
            }
            
            // Extraire tout le texte détecté
            let recognizedText = observations.compactMap { observation in
                return observation.topCandidates(1).first?.string
            }.joined(separator: " ")
            
            let cleanedText = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
            
            print("[OCRService] Texte extrait: \(cleanedText)")
            completion(cleanedText.isEmpty ? nil : cleanedText)
        }
        
        // Configuration pour une précision maximale
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false // Désactivé pour éviter les corrections indésirables
        
        // Langues supportées (français et anglais)
        request.recognitionLanguages = ["fr-FR", "en-US"]
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("[OCRService] Erreur lors de l'exécution OCR: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    /// Nettoie et formate le texte OCR pour les métadonnées
    func cleanOCRText(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
