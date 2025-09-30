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

class ShareViewController: NSViewController {

    override var nibName: NSNib.Name? {
        return nil
    }

    // UI Elements
    private var categoryPopup: NSPopUpButton!
    private var titleLabel: NSTextField!
    private var saveButton: NSButton!
    private var cancelButton: NSButton!
    
    // Data
    private var pendingURL: URL?
    private var pendingTitle: String?
    private var pendingImageData: Data?
    private var availableCategories: [Category] = []
    
    override func loadView() {
        // Créer une vue avec taille appropriée
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 180))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        self.view = view
        
        // Créer l'interface
        setupUI()
        
        // Charger les catégories et traiter l'URL
        loadCategoriesAndProcessURL()
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
                        if let nsImage = image as? NSImage {
                            // Redimensionner et compresser l'image (comme sur iOS)
                            let maxSize: CGFloat = 800
                            let size = nsImage.size
                            let ratio = min(maxSize / size.width, maxSize / size.height)
                            
                            if ratio < 1 {
                                let newSize = NSSize(width: size.width * ratio, height: size.height * ratio)
                                let resizedImage = NSImage(size: newSize)
                                resizedImage.lockFocus()
                                nsImage.draw(in: NSRect(origin: .zero, size: newSize))
                                resizedImage.unlockFocus()
                                
                                if let tiffData = resizedImage.tiffRepresentation,
                                   let bitmapImage = NSBitmapImageRep(data: tiffData) {
                                    // Compression JPEG 70% (comme iOS)
                                    imageData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.7])
                                }
                            } else {
                                // Image déjà petite, juste compresser
                                if let tiffData = nsImage.tiffRepresentation,
                                   let bitmapImage = NSBitmapImageRep(data: tiffData) {
                                    imageData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.7])
                                }
                            }
                        }
                        
                        self?.saveToSwiftData(url: url, title: finalTitle, imageData: imageData)
                    }
                } else {
                    self?.saveToSwiftData(url: url, title: finalTitle, imageData: nil)
                }
            }
        }
    }
    
    private func saveToSwiftData(url: URL, title: String, imageData: Data?) {
        Task { @MainActor in
            do {
                let schema = Schema([ContentItem.self, Category.self])
                
                // IMPORTANT : Utiliser l'App Group pour partager avec l'app principale
                let configuration = ModelConfiguration(
                    schema: schema,
                    groupContainer: .identifier("group.com.misericode.pinpin"),
                    cloudKitDatabase: .private("iCloud.com.misericode.Pinpin")
                )
                let container = try ModelContainer(for: schema, configurations: [configuration])
                let context = container.mainContext
                
                // Trouver ou créer la catégorie "Général"
                let categoryDescriptor = FetchDescriptor<Category>(
                    predicate: #Predicate { $0.name == "Général" }
                )
                let categories = try context.fetch(categoryDescriptor)
                let category: Category
                
                if let existingCategory = categories.first {
                    category = existingCategory
                } else {
                    category = Category(name: "Général")
                    context.insert(category)
                }
                
                // Créer le ContentItem
                let item = ContentItem(
                    title: title,
                    url: url.absoluteString,
                    imageData: imageData,
                    category: category
                )
                
                context.insert(item)
                try context.save()
                
                // Afficher une notification système
                showNotification(title: "Added to Pinpin", subtitle: title)
                closeImmediately()
            } catch {
                closeImmediately()
            }
        }
    }
    
    private func closeImmediately() {
        DispatchQueue.main.async { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
    
    private func showNotification(title: String, subtitle: String) {
        let center = UNUserNotificationCenter.current()
        
        // Demander la permission
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            
            // Créer la notification
            let content = UNMutableNotificationContent()
            content.title = title
            content.subtitle = subtitle
            content.sound = .default
            
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
            
            center.add(request)
        }
    }

}
