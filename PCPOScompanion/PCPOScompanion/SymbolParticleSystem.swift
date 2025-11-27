import SwiftUI

// MARK: - Individual Symbol Particle (Independently Moving)

struct SymbolParticle: View, Identifiable {
    let id = UUID()
    let symbolName: String
    let color: Color
    let weight: Font.Weight
    let size: CGFloat
    
    @State private var offset: CGSize = .zero
    @State private var rotation: Angle = .zero
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    
    // Individual motion parameters
    let motionAmplitude: CGFloat
    let motionFrequency: Double
    let rotationSpeed: Double
    let randomSeed: Double
    
    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: size, weight: weight))
            .foregroundStyle(
                .linearGradient(
                    colors: [color, color.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .offset(offset)
            .rotationEffect(rotation)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                startIndependentMotion()
            }
    }
    
    private func startIndependentMotion() {
        // Unique phase based on random seed
        let phase = randomSeed * 2 * .pi
        
        // Orbit motion
        withAnimation(
            .linear(duration: 2.0 / motionFrequency)
                .repeatForever(autoreverses: false)
        ) {
            offset = CGSize(
                width: cos(phase) * motionAmplitude,
                height: sin(phase) * motionAmplitude
            )
        }
        
        // Rotation
        withAnimation(
            .linear(duration: 3.0 / rotationSpeed)
                .repeatForever(autoreverses: false)
        ) {
            rotation = .degrees(360)
        }
        
        // Breathing scale
        withAnimation(
            .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
        ) {
            scale = 0.8 + 0.4 * CGFloat(randomSeed)
        }
        
        // Subtle opacity pulse
        withAnimation(
            .easeInOut(duration: 2.0 + randomSeed)
                .repeatForever(autoreverses: true)
        ) {
            opacity = 0.6 + 0.4 * randomSeed
        }
    }
}

// MARK: - Multi-Layer Symbol Field (Orchestrator)

struct MultiLayerSymbolField: View {
    let state: FaceIDState
    let intensity: Double
    let color: Color
    
    @State private var particles: [SymbolParticle] = []
    @State private var layerRotation: Angle = .zero
    
    var body: some View {
        ZStack {
            // Background layer (slow rotation)
            ForEach(particles.prefix(particles.count / 3)) { particle in
                particle
            }
            .rotationEffect(layerRotation * 0.5)
            
            // Middle layer (medium rotation)
            ForEach(particles.dropFirst(particles.count / 3).prefix(particles.count / 3)) { particle in
                particle
            }
            .rotationEffect(layerRotation)
            
            // Foreground layer (fast rotation)
            ForEach(particles.dropFirst(2 * particles.count / 3)) { particle in
                particle
            }
            .rotationEffect(layerRotation * 1.5)
        }
        .onAppear {
            generateParticles()
            startLayerRotation()
        }
        .onChange(of: state) { newState in
            regenerateParticles(for: newState)
        }
    }
    
    private func generateParticles() {
        let symbols = FaceIDSymbolLibrary.symbolsFor(state: state, intensity: intensity)
        
        particles = symbols.enumerated().map { index, symbol in
            SymbolParticle(
                symbolName: symbol,
                color: color,
                weight: randomWeight(),
                size: CGFloat.random(in: 12...24),
                motionAmplitude: CGFloat.random(in: 20...60),
                motionFrequency: Double.random(in: 0.5...2.0),
                rotationSpeed: Double.random(in: 0.3...1.5),
                randomSeed: Double.random(in: 0...1)
            )
        }
    }
    
    private func regenerateParticles(for newState: FaceIDState) {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            generateParticles()
        }
    }
    
    private func startLayerRotation() {
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            layerRotation = .degrees(360)
        }
    }
    
    private func randomWeight() -> Font.Weight {
        [.thin, .light, .regular, .medium, .semibold, .bold].randomElement() ?? .regular
    }
}

// MARK: - Thickness Pulse System

struct ThicknessPulsingSymbol: View {
    let symbolName: String
    let baseColor: Color
    let intensity: Double
    
    @State private var currentWeight: Font.Weight = .regular
    @State private var thickness: CGFloat = 1.0
    
    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: 40, weight: currentWeight))
            .foregroundStyle(baseColor)
            .shadow(color: baseColor.opacity(intensity * 0.5), radius: intensity * 10)
            .onAppear {
                startThicknessPulse()
            }
    }
    
    private func startThicknessPulse() {
        let weights: [Font.Weight] = [.thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black]
        
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            thickness = 0.5 + intensity
        }
        
        // Cycle through weights
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                currentWeight = weights.randomElement() ?? .regular
            }
        }
    }
}
