//
//  ErrorHandler.swift
//  Pinpin
//
//  Service centralisé pour la gestion des erreurs
//

import Foundation
import SwiftUI

/// Erreurs spécifiques à Pinpin
enum PinpinError: LocalizedError {
    case dataServiceError(String)
    case imageOptimizationFailed
    case categoryNotFound(String)
    case invalidURL(String)
    case fileSystemError(String)
    case cloudSyncError(String)
    case ocrFailed
    case metadataParsingFailed
    
    var errorDescription: String? {
        switch self {
        case .dataServiceError(let message):
            return "Data error: \(message)"
        case .imageOptimizationFailed:
            return "Failed to optimize image"
        case .categoryNotFound(let name):
            return "Category '\(name)' not found"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .fileSystemError(let message):
            return "File system error: \(message)"
        case .cloudSyncError(let message):
            return "iCloud sync error: \(message)"
        case .ocrFailed:
            return "Text recognition failed"
        case .metadataParsingFailed:
            return "Failed to parse metadata"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .dataServiceError:
            return "Try restarting the app"
        case .imageOptimizationFailed:
            return "The image may be corrupted"
        case .categoryNotFound:
            return "Create the category first"
        case .invalidURL:
            return "Check the URL format"
        case .fileSystemError:
            return "Check storage permissions"
        case .cloudSyncError:
            return "Check iCloud settings"
        case .ocrFailed:
            return "The image may not contain readable text"
        case .metadataParsingFailed:
            return "The data format may be invalid"
        }
    }
}

/// Service de gestion des erreurs
@MainActor
final class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    
    @Published var currentError: PinpinError?
    @Published var showErrorAlert = false
    
    private init() {}
    
    /// Gère une erreur et décide de l'afficher ou non
    func handle(_ error: Error, silent: Bool = false) {
        // Log l'erreur
        logError(error)
        
        // Convertir en PinpinError si possible
        if let pinpinError = error as? PinpinError {
            currentError = pinpinError
            if !silent {
                showErrorAlert = true
            }
        } else {
            // Erreur générique
            currentError = .dataServiceError(error.localizedDescription)
            if !silent {
                showErrorAlert = true
            }
        }
    }
    
    /// Log une erreur dans la console
    private func logError(_ error: Error) {
        if let pinpinError = error as? PinpinError {
            print("❌ [Pinpin Error] \(pinpinError.errorDescription ?? "Unknown error")")
            if let suggestion = pinpinError.recoverySuggestion {
                print("💡 [Suggestion] \(suggestion)")
            }
        } else {
            print("❌ [Error] \(error.localizedDescription)")
        }
    }
    
    /// Efface l'erreur courante
    func clearError() {
        currentError = nil
        showErrorAlert = false
    }
}
