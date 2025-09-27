import SwiftUI

// MARK: - Poof Transition
extension AnyTransition {
    static var poof: AnyTransition {
        .asymmetric(
            insertion: .identity,
            removal: .modifier(
                active: PoofModifier(progress: 0),
                identity: PoofModifier(progress: 1)
            )
        )
    }
}

// MARK: - Poof Modifier
struct PoofModifier: ViewModifier {
    let progress: Double
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(1 - progress * 0.3) // L'item rétrécit légèrement
            .opacity(1 - progress) // L'item disparaît
            .overlay(
                // Nuage de particules
                PoofParticlesView(progress: progress)
                    .allowsHitTesting(false)
            )
    }
}

// MARK: - Particules Poof
struct PoofParticlesView: View {
    let progress: Double
    private let particleCount = 12
    
    var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { index in
                PoofParticle(
                    progress: progress,
                    angle: Double(index) * (360.0 / Double(particleCount)),
                    delay: Double(index) * 0.02
                )
            }
        }
    }
}

// MARK: - Particule Individuelle
struct PoofParticle: View {
    let progress: Double
    let angle: Double
    let delay: Double
    
    private var adjustedProgress: Double {
        max(0, min(1, (progress - delay) / (1 - delay)))
    }
    
    private var particleOffset: CGSize {
        let distance = adjustedProgress * 60 // Distance maximale
        let radians = angle * .pi / 180
        return CGSize(
            width: cos(radians) * distance,
            height: sin(radians) * distance
        )
    }
    
    private var particleScale: Double {
        if adjustedProgress < 0.3 {
            // Croissance rapide
            return adjustedProgress * 3.33
        } else {
            // Rétrécissement
            return max(0, 1 - (adjustedProgress - 0.3) * 1.43)
        }
    }
    
    private var particleOpacity: Double {
        if adjustedProgress < 0.2 {
            // Apparition
            return adjustedProgress * 5
        } else {
            // Disparition
            return max(0, 1 - (adjustedProgress - 0.2) * 1.25)
        }
    }
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [.white, .gray.opacity(0.8)],
                    center: .center,
                    startRadius: 0,
                    endRadius: 8
                )
            )
            .frame(width: 16, height: 16)
            .scaleEffect(particleScale)
            .opacity(particleOpacity)
            .offset(particleOffset)
            .blur(radius: adjustedProgress * 2)
    }
}

// MARK: - Version Colorée
extension AnyTransition {
    static func poof(color: Color = .gray) -> AnyTransition {
        .asymmetric(
            insertion: .identity,
            removal: .modifier(
                active: ColoredPoofModifier(progress: 0, color: color),
                identity: ColoredPoofModifier(progress: 1, color: color)
            )
        )
    }
}

struct ColoredPoofModifier: ViewModifier {
    let progress: Double
    let color: Color
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(1 - progress * 0.3)
            .opacity(1 - progress)
            .overlay(
                ColoredPoofParticlesView(progress: progress, color: color)
                    .allowsHitTesting(false)
            )
    }
}

struct ColoredPoofParticlesView: View {
    let progress: Double
    let color: Color
    private let particleCount = 15
    
    var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { index in
                ColoredPoofParticle(
                    progress: progress,
                    angle: Double(index) * (360.0 / Double(particleCount)) + Double.random(in: -15...15),
                    delay: Double(index) * 0.015,
                    color: color
                )
            }
        }
    }
}

struct ColoredPoofParticle: View {
    let progress: Double
    let angle: Double
    let delay: Double
    let color: Color
    
    private var adjustedProgress: Double {
        max(0, min(1, (progress - delay) / (1 - delay)))
    }
    
    private var particleOffset: CGSize {
        let baseDistance = Double.random(in: 40...80)
        let distance = adjustedProgress * baseDistance
        let radians = angle * .pi / 180
        return CGSize(
            width: cos(radians) * distance,
            height: sin(radians) * distance
        )
    }
    
    private var particleScale: Double {
        let randomScale = Double.random(in: 0.5...1.5)
        if adjustedProgress < 0.3 {
            return adjustedProgress * 3.33 * randomScale
        } else {
            return max(0, (1 - (adjustedProgress - 0.3) * 1.43) * randomScale)
        }
    }
    
    private var particleOpacity: Double {
        if adjustedProgress < 0.2 {
            return adjustedProgress * 5
        } else {
            return max(0, 1 - (adjustedProgress - 0.2) * 1.25)
        }
    }
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(0.9), color.opacity(0.3)],
                    center: .center,
                    startRadius: 0,
                    endRadius: 6
                )
            )
            .frame(width: Double.random(in: 8...20), height: Double.random(in: 8...20))
            .scaleEffect(particleScale)
            .opacity(particleOpacity)
            .offset(particleOffset)
            .blur(radius: adjustedProgress * 1.5)
    }
}

// MARK: - Preview
struct PoofTransition_Previews: PreviewProvider {
    static var previews: some View {
        PoofTestView()
    }
}

struct PoofTestView: View {
    @State private var showItem = true
    
    var body: some View {
        VStack(spacing: 40) {
            Text("Animation Poof Native")
                .font(.title)
                .padding()
            
            if showItem {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.blue.gradient)
                    .frame(width: 120, height: 80)
                    .overlay(
                        Text("Poof!")
                            .foregroundColor(.white)
                            .font(.headline)
                    )
                    .transition(.poof)
            }
            
            Button("Toggle Poof") {
                withAnimation(.easeOut(duration: 0.6)) {
                    showItem.toggle()
                }
            }
            .padding()
            .background(.gray.opacity(0.2))
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.1))
    }
}
