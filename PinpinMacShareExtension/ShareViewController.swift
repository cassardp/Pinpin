//
//  ShareViewController.swift
//  PinpinMacShareExtension
//
//  Share Extension Mac avec SwiftData
//

import Cocoa
import UniformTypeIdentifiers
import SwiftData
import LinkPresentation
import UserNotifications
import Vision

class ShareViewController: NSViewController {

    override var nibName: NSNib.Name? {
        return nil
    }
    
    override func loadView() {
        print("🚀 [ShareExtension] loadView appelé")
        // Créer une vue minimale (invisible)
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 1, height: 1))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        
        self.view = view
        
        // Traiter l'URL directement (pas d'UI)
        processURL()
    }
    
    private func dismissViewController() {
        if let window = view.window {
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = false
            window.alphaValue = 0
            window.orderOut(nil)
        }
    }
    
    private func processURL() {
        print("🔍 [ShareExtension] processURL démarré")
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem else {
            print("❌ [ShareExtension] Pas d'extensionItem")
            closeImmediately()
            return
        }
        
        let attachments = extensionItem.attachments ?? []
        print("📎 [ShareExtension] \(attachments.count) attachment(s) trouvé(s)")

        if let attachment = attachments.first {
            // Essayer tous les types (code original inchangé)

            // Utiliser loadObject au lieu de loadItem (solution macOS)
            if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                print("🔗 [ShareExtension] Type URL détecté, chargement...")
                _ = attachment.loadObject(ofClass: URL.self) { [weak self] (url, error) in
                    if let url = url {
                        print("✅ [ShareExtension] URL chargée: \(url.absoluteString)")
                        self?.handleURL(url, title: extensionItem.attributedContentText?.string)
                    } else {
                        print("❌ [ShareExtension] Erreur chargement URL: \(error?.localizedDescription ?? "unknown")")
                        self?.closeImmediately()
                    }
                }
                return
            }

            // Essayer plainText
            if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] (item, error) in
                    if let urlString = item as? String, let url = URL(string: urlString) {
                        self?.handleURL(url, title: urlString)
                    } else {
                        self?.closeImmediately()
                    }
                }
                return
            }
        }

        // Sur macOS, le texte sélectionné arrive dans attributedContentText
        // avec un tableau attachments vide
        if let text = extensionItem.attributedContentText?.string, !text.isEmpty {
            print("📝 [ShareExtension] Texte trouvé dans attributedContentText")
            handleText(text)
            return
        }

        closeImmediately()
    }
    
    private func handleText(_ text: String) {
        if let detectedURL = extractURLFromText(text) {
            handleURL(detectedURL, title: text)
        } else {
            saveTextToSwiftData(title: text, description: text)
        }
    }

    private func extractURLFromText(_ text: String) -> URL? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        return matches?.first?.url
    }

    private func saveTextToSwiftData(title: String, description: String) {
        print("💾 [ShareExtension] saveTextToSwiftData démarré pour: \(title)")
        Task { @MainActor in
            guard FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.misericode.pinpin") != nil else {
                print("❌ [ShareExtension] Accès App Group refusé")
                closeImmediately()
                return
            }

            do {
                let schema = Schema([ContentItem.self, Category.self])
                let configuration = ModelConfiguration(
                    schema: schema,
                    groupContainer: .identifier(AppConstants.groupID),
                    cloudKitDatabase: .private(AppConstants.cloudKitContainerID)
                )
                let container = try ModelContainer(for: schema, configurations: [configuration])
                let context = container.mainContext

                let contentTitle = title
                let tenSecondsAgo = Date().addingTimeInterval(-10)
                let duplicateDescriptor = FetchDescriptor<ContentItem>(
                    predicate: #Predicate { item in
                        item.title == contentTitle &&
                        item.createdAt > tenSecondsAgo
                    }
                )
                if (try? context.fetch(duplicateDescriptor).first) != nil {
                    print("⚠️ [ShareExtension] Doublon détecté, skip")
                    self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                    return
                }

                let categoryDescriptor = FetchDescriptor<Category>(
                    predicate: #Predicate { $0.name == "Misc" }
                )
                let category = try context.fetch(categoryDescriptor).first ?? {
                    let misc = Category(name: "Misc")
                    context.insert(misc)
                    return misc
                }()

                let item = ContentItem(
                    title: title,
                    itemDescription: description,
                    url: nil,
                    imageData: nil,
                    metadata: nil,
                    category: category
                )
                context.insert(item)
                try context.save()
                print("✅ Texte sauvegardé: \(title)")

                let content = UNMutableNotificationContent()
                content.title = "Added to Pinpin"
                content.body = title
                content.sound = .default
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                Task {
                    try? await UNUserNotificationCenter.current().add(request)
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.closeImmediately()
                }
            } catch {
                print("❌ [ShareExtension] Erreur sauvegarde texte: \(error)")
                closeImmediately()
            }
        }
    }

    private func handleURL(_ url: URL, title: String?) {
        print("🎯 [ShareExtension] handleURL appelé pour: \(url.absoluteString)")
        let displayTitle = title ?? url.host ?? url.absoluteString
        
        // Récupérer les métadonnées (avec image)
        let metadataProvider = LPMetadataProvider()
        metadataProvider.startFetchingMetadata(for: url) { [weak self] metadata, error in
            DispatchQueue.main.async {
                let finalTitle = metadata?.title ?? displayTitle
                
                // Récupérer l'image directement
                if let imageProvider = metadata?.imageProvider {
                    _ = imageProvider.loadObject(ofClass: NSImage.self) { image, _ in
                        var imageData: Data? = nil
                        var ocrText: String? = nil
                        
                        if let nsImage = image as? NSImage {
                            // Redimensionner et compresser l'image (comme sur iOS)
                            let maxSize: CGFloat = 800
                            let size = nsImage.size
                            let ratio = min(maxSize / size.width, maxSize / size.height)
                            
                            let finalImage: NSImage
                            if ratio < 1 {
                                let newSize = NSSize(width: size.width * ratio, height: size.height * ratio)
                                let resizedImage = NSImage(size: newSize)
                                resizedImage.lockFocus()
                                nsImage.draw(in: NSRect(origin: .zero, size: newSize))
                                resizedImage.unlockFocus()
                                finalImage = resizedImage
                                
                                if let tiffData = resizedImage.tiffRepresentation,
                                   let bitmapImage = NSBitmapImageRep(data: tiffData) {
                                    // Compression JPEG 70% (comme iOS)
                                    imageData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.7])
                                }
                            } else {
                                // Image déjà petite, juste compresser
                                finalImage = nsImage
                                if let tiffData = nsImage.tiffRepresentation,
                                   let bitmapImage = NSBitmapImageRep(data: tiffData) {
                                    imageData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.7])
                                }
                            }
                            
                            // Lancer l'OCR sur l'image
                            let semaphore = DispatchSemaphore(value: 0)
                            OCRService.shared.extractText(from: finalImage) { extractedText in
                                if let text = extractedText, !text.isEmpty {
                                    ocrText = OCRService.shared.cleanOCRText(text)
                                    print("[ShareExtension] OCR extrait: \(ocrText ?? "")")
                                }
                                semaphore.signal()
                            }
                            semaphore.wait()
                        }
                        
                        self?.saveToSwiftData(url: url, title: finalTitle, imageData: imageData, ocrText: ocrText)
                    }
                } else {
                    self?.saveToSwiftData(url: url, title: finalTitle, imageData: nil, ocrText: nil)
                }
            }
        }
    }
    
    private func saveToSwiftData(url: URL, title: String, imageData: Data?, ocrText: String?) {
        print("💾 [ShareExtension] saveToSwiftData démarré pour: \(title)")
        Task { @MainActor in
            // Vérifier si on a accès à l'App Group avant de continuer
            guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.misericode.pinpin") else {
                print("❌ [ShareExtension] Accès App Group refusé ou non configuré")
                closeImmediately()
                return
            }
            print("✅ [ShareExtension] App Group accessible: \(groupURL.path)")
            
            // Vérifier si on peut accéder au dossier
            guard FileManager.default.isReadableFile(atPath: groupURL.path) else {
                print("❌ Pas de permission de lecture sur l'App Group")
                closeImmediately()
                return
            }
            
            do {
                print("🗄️ [ShareExtension] Création du ModelContainer...")
                let schema = Schema([ContentItem.self, Category.self])
                
                // IMPORTANT : Utiliser le même container CloudKit que l'app principale et iOS
                let configuration = ModelConfiguration(
                    schema: schema,
                    groupContainer: .identifier(AppConstants.groupID),
                    cloudKitDatabase: .private(AppConstants.cloudKitContainerID)
                )
                
                let container = try ModelContainer(for: schema, configurations: [configuration])
                print("✅ [ShareExtension] ModelContainer créé avec CloudKit: \(AppConstants.cloudKitContainerID)")
                let context = container.mainContext

                // Vérifier si un item identique a été créé récemment (évite les doublons accidentels)
                let tenSecondsAgo = Date().addingTimeInterval(-10)
                let urlString = url.absoluteString
                let duplicateDescriptor = FetchDescriptor<ContentItem>(
                    predicate: #Predicate { item in
                        item.title == title &&
                        item.url == urlString &&
                        item.createdAt > tenSecondsAgo
                    }
                )
                
                if let existingItem = try? context.fetch(duplicateDescriptor).first {
                    print("⚠️ Item identique créé il y a \(Int(Date().timeIntervalSince(existingItem.createdAt)))s, skip pour éviter doublon accidentel")
                    DispatchQueue.main.async {
                        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                    }
                    return
                }

                // Trouver ou créer la catégorie "Misc"
                let categoryDescriptor = FetchDescriptor<Category>(
                    predicate: #Predicate { $0.name == "Misc" }
                )
                let category = try context.fetch(categoryDescriptor).first ?? {
                    let misc = Category(name: "Misc")
                    context.insert(misc)
                    return misc
                }()

                // Préparer les métadonnées OCR
                var metadata: Data? = nil
                if let ocrText = ocrText {
                    let metadataDict = ["ocr_text": ocrText]
                    metadata = try? JSONEncoder().encode(metadataDict)
                }

                // Créer le ContentItem
                let item = ContentItem(
                    title: title,
                    url: url.absoluteString,
                    imageData: imageData,
                    metadata: metadata,
                    category: category
                )

                context.insert(item)
                try context.save()
                
                print("✅ Contenu sauvegardé: \(title)")

                // Notification de confirmation (UserNotifications framework moderne)
                let content = UNMutableNotificationContent()
                content.title = "Added to Pinpin"
                content.body = title
                content.sound = .default
                
                let request = UNNotificationRequest(
                    identifier: UUID().uuidString,
                    content: content,
                    trigger: nil // Immediate delivery
                )
                
                Task {
                    do {
                        try await UNUserNotificationCenter.current().add(request)
                    } catch {
                        print("⚠️ [ShareExtension] Notification error (expected in extensions): \(error.localizedDescription)")
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.closeImmediately()
                }
                
            } catch {
                print("❌ [ShareExtension] Erreur lors de la sauvegarde: \(error.localizedDescription)")
                print("❌ [ShareExtension] Erreur détaillée: \(error)")
                closeImmediately()
            }
        }
    }
    
    private func closeImmediately() {
        DispatchQueue.main.async { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }

}
