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
    @Binding var swipeProgress: CGFloat
    var width: CGFloat = 320
    var isSwipeDisabled: Bool = false // Nouveau paramètre pour désactiver le swipe
    @ViewBuilder var content: () -> Content
    @ViewBuilder var drawer: () -> Drawer

    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    // Stricter horizontal swipe detection to avoid diagonal swipes
    private let horizontalBiasRatio: CGFloat = 3.0         // |dx| must be >= ratio * |dy|
    private let maxVerticalDeviation: CGFloat = 20.0       // vertical movement must stay under this (pts)
    private let minHorizontalTrigger: CGFloat = 12.0       // need some horizontal intent before locking

    var body: some View {
        GeometryReader { geo in
            let currentOffset = isOpen ? width : 0
            let totalOffset = currentOffset + dragOffset
            
            // Calculer la progression du swipe (0.0 = fermé, 1.0 = ouvert)
            let progress = max(0, min(1, totalOffset / width))
            
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
            .onChange(of: progress) {
                swipeProgress = progress
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        // Ne pas traiter le swipe si désactivé
                        guard !isSwipeDisabled else { return }
                        
                        let dx = value.translation.width
                        let dy = value.translation.height
                        
                        // Suivi avec verrou directionnel horizontal strict
                        if dx != 0 || dy != 0 {
                            // N'activer le drag horizontal que si l'intention est claire
                            let absDx = abs(dx)
                            let absDy = abs(dy)
                            let hasHorizontalIntent = absDx >= minHorizontalTrigger
                            let isMostlyHorizontal = absDx >= horizontalBiasRatio * absDy
                            let verticalUnderLimit = absDy <= maxVerticalDeviation

                            if (isDragging || (hasHorizontalIntent && isMostlyHorizontal && verticalUnderLimit)) {
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
                        // Ne pas traiter la fin du swipe si désactivé
                        guard !isSwipeDisabled else { return }
                        
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
