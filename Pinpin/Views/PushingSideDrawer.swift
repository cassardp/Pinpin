//
//  PushingSideDrawer.swift
//  Pinpin
//
//  Composant de tiroir latéral performant qui pousse le contenu
//

import SwiftUI

/// Side drawer qui pousse le contenu (depuis la gauche).
struct PushingSideDrawer<Content: View, Drawer: View>: View {
    @Binding var isOpen: Bool
    var width: CGFloat = 320
    @ViewBuilder var content: () -> Content
    @ViewBuilder var drawer: () -> Drawer

    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false

    var body: some View {
        GeometryReader { geo in
            let currentOffset = isOpen ? width : 0
            let totalOffset = currentOffset + dragOffset

            ZStack {
                // Le contenu est poussé vers la droite
                content()
                    .offset(x: totalOffset)
                    .disabled(isOpen || isDragging)

                // Le tiroir, ancré à gauche
                HStack {
                    drawer()
                        .frame(width: width)
                        .ignoresSafeArea(edges: .vertical)
                        .offset(x: totalOffset - width)
                        .allowsHitTesting(!isDragging)
                    Spacer(minLength: 0)
                }

                // Zone de tap pour fermer (seulement sur le contenu principal)
                if isOpen {
                    HStack {
                        Spacer(minLength: 0)
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture { 
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                withAnimation(.snappy(duration: 0.22)) { 
                                    isOpen = false 
                                } 
                            }
                            .frame(width: geo.size.width - width)
                    }
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let dx = value.translation.width
                        let dy = value.translation.height
                        
                        // Suivi immédiat avec détection strictement horizontale
                        if dx != 0 || dy != 0 {
                            // Détection stricte pour éviter l'interférence avec le scroll vertical
                            if abs(dx) > abs(dy) {
                                isDragging = true
                                
                                if isOpen {
                                    // Menu ouvert : suivi immédiat vers la gauche
                                    if dx <= 0 {
                                        dragOffset = max(dx, -width)
                                    }
                                } else {
                                    // Menu fermé : suivi immédiat vers la droite
                                    if dx >= 0 {
                                        dragOffset = min(dx, width)
                                    }
                                }
                            }
                        }
                    }
                    .onEnded { value in
                        let dx = value.translation.width
                        
                        defer { 
                            isDragging = false
                        }
                        
                        guard isDragging else {
                            dragOffset = 0
                            return
                        }
                        
                        withAnimation(.snappy(duration: 0.22)) {
                            if isOpen {
                                // Fermer si swipe gauche > 25% de la largeur OU vitesse rapide
                                let velocity = value.predictedEndTranslation.width - dx
                                if dx < -width * 0.25 || velocity < -200 {
                                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                    isOpen = false
                                }
                            } else {
                                // Ouvrir si swipe droite > 25% de la largeur OU vitesse rapide
                                let velocity = value.predictedEndTranslation.width - dx
                                if dx > width * 0.25 || velocity > 200 {
                                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                    isOpen = true
                                }
                            }
                            dragOffset = 0
                        }
                    }
            )
            .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.86, blendDuration: 0), value: isOpen)
        }
    }
}
