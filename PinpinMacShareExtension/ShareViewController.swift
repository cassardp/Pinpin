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
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem else {
            closeImmediately()
            return
        }
        
        guard let attachments = extensionItem.attachments, !attachments.isEmpty else {
            closeImmediately()
            return
        }
        
        // Essayer tous les types
        let attachment = attachments[0]
        
        // Utiliser loadObject au lieu de loadItem (solution macOS)
        if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            _ = attachment.loadObject(ofClass: URL.self) { [weak self] (url, error) in
                if let url = url {
                    self?.handleURL(url, title: extensionItem.attributedContentText?.string)
                } else {
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
        
        closeImmediately()
    }
    
    private func handleURL(_ url: URL, title: String?) {
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
        Task { @MainActor in
            // Vérifier si on a accès à l'App Group avant de continuer
            guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.misericode.pinpin") else {
                print("❌ Accès App Group refusé ou non configuré")
                closeImmediately()
                return
            }
            
            // Vérifier si on peut accéder au dossier
            guard FileManager.default.isReadableFile(atPath: groupURL.path) else {
                print("❌ Pas de permission de lecture sur l'App Group")
                closeImmediately()
                return
            }
            
            do {
                let schema = Schema([ContentItem.self, Category.self])
                
                // IMPORTANT : Utiliser l'App Group pour partager avec l'app principale
                let configuration = ModelConfiguration(
                    schema: schema,
                    groupContainer: .identifier("group.com.misericode.pinpin"),
                    cloudKitDatabase: .automatic
                )
                
                let container = try ModelContainer(for: schema, configurations: [configuration])
                let context = container.mainContext
                
                // Trouver ou créer la catégorie "Misc"
                let categoryDescriptor = FetchDescriptor<Category>(
                    predicate: #Predicate { $0.name == "Misc" }
                )
                let categories = try context.fetch(categoryDescriptor)
                let category: Category
                
                if let existingCategory = categories.first {
                    category = existingCategory
                } else {
                    category = Category(name: "Misc")
                    context.insert(category)
                }
                
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

                // NSUserNotification est deprecated mais c'est la seule API qui fonctionne dans les Share Extensions
                // UNUserNotification ne fonctionne pas dans les extensions (permissions refusées)
                let notification = NSUserNotification()
                notification.title = "Added to Pinpin"
                notification.informativeText = title
                notification.soundName = NSUserNotificationDefaultSoundName
                NSUserNotificationCenter.default.deliver(notification)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.closeImmediately()
                }
                
            } catch {
                print("❌ Erreur lors de la sauvegarde: \(error.localizedDescription)")
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
