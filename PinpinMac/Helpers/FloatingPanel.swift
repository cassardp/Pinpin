//
//  FloatingPanel.swift
//  PinpinMac
//
//  Panel flottant qui se ferme quand on clique à l'extérieur
//

import SwiftUI
import SwiftData
import AppKit

/// Un panel flottant macOS qui se ferme automatiquement quand on clique à l'extérieur
class FloatingPanel: NSPanel {
    
    init(contentRect: NSRect, hostingView: NSView, onClose: @escaping () -> Void) {
        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        // Configuration du panel
        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.transient, .ignoresCycle]
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = true
        self.hidesOnDeactivate = false
        self.becomesKeyOnlyIfNeeded = false
        
        // Masquer les boutons standard (rouge, jaune, vert)
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
        
        self.contentView = hostingView
        
        // Observer pour fermer quand on perd le focus
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: self,
            queue: .main
        ) { [weak self] _ in
            self?.close()
            onClose()
        }
    }
    
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    
    // Fermer avec Escape
    override func cancelOperation(_ sender: Any?) {
        close()
    }
}

/// ViewModifier pour afficher un floating panel au lieu d'une sheet
struct FloatingPanelModifier<PanelContent: View>: ViewModifier {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    let panelContent: () -> PanelContent
    
    @State private var panel: FloatingPanel?
    
    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { _, newValue in
                if newValue {
                    showPanel()
                } else {
                    hidePanel()
                }
            }
    }
    
    private func showPanel() {
        guard panel == nil else { return }
        
        // Obtenir la position de la fenêtre principale
        guard let mainWindow = NSApp.keyWindow ?? NSApp.mainWindow else { return }
        let mainFrame = mainWindow.frame
        
        // Créer le panel centré sur la fenêtre principale
        let panelSize = NSSize(width: 450, height: 300)
        let panelOrigin = NSPoint(
            x: mainFrame.midX - panelSize.width / 2,
            y: mainFrame.midY - panelSize.height / 2
        )
        let panelRect = NSRect(origin: panelOrigin, size: panelSize)
        
        // Créer le contenu avec le modelContext injecté
        let contentWithEnvironment = panelContent()
            .modelContext(modelContext)
        
        let hostingView = NSHostingView(rootView: contentWithEnvironment)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        
        let newPanel = FloatingPanel(
            contentRect: panelRect,
            hostingView: hostingView,
            onClose: {
                isPresented = false
                panel = nil
            }
        )
        
        panel = newPanel
        newPanel.makeKeyAndOrderFront(nil)
    }
    
    private func hidePanel() {
        panel?.close()
        panel = nil
    }
}

extension View {
    /// Affiche un panel flottant qui se ferme quand on clique à l'extérieur (macOS uniquement)
    func floatingPanel<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.modifier(FloatingPanelModifier(isPresented: isPresented, panelContent: content))
    }
}
