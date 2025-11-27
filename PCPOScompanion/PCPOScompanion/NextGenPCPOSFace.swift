import SwiftUI

/// Next-Gen PCPOS Face with SF Symbols Animation Fusion
/// Combines custom shapes with SF Symbols effects for advanced animations
struct NextGenPCPOSFace: View {
    @ObservedObject var faceModel: PCPOSFaceModel
    @ObservedObject var speechManager: SpeechManager
    
    // Animation state driven by PersonalityEngine
    @State private var currentEmotion: String = "NEUTRAL"
    @State private var isBlinking: Bool = false
    @State private var isPulsing: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            
            ZStack {
                // Background Circle with breathing effect
                Circle()
                    .fill(Color.black)
                    .overlay(
                        Circle()
                            .stroke(Color(hex: faceModel.profile.appearance.colors.primary), lineWidth: 3)
                    )
                
                // Animated Face ID Brackets (SF Symbols)
                animatedBrackets(size: size)
                
                // Face Features Layer
                faceFeatures(size: size)
                
                // Emotion Indicator (SF Symbol)
                emotionIndicator
                    .offset(x: size * 0.4, y: -size * 0.4)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onChange(of: faceModel.profile.geometry.eyeLeft.openness) { newValue in
            isBlinking = newValue > 0.3
        }
        .onChange(of: speechManager.isSpeaking) { speaking in
            isPulsing = speaking
        }
    }
    
    // MARK: - SF Symbols Animated Brackets
    
    @ViewBuilder
    private func animatedBrackets(size: CGFloat) -> some View {
        ZStack {
            // Corner brackets using SF Symbols with next-gen effects
            ForEach(0..<4, id: \.self) { index in
                Image(systemName: "l.square")
                    .font(.system(size: size * 0.15))
                    .foregroundStyle(Color(hex: faceModel.profile.appearance.colors.primary))
                    .rotationEffect(.degrees(Double(index) * 90))
                    .offset(
                        x: index % 2 == 0 ? -size * 0.35 : size * 0.35,
                        y: index < 2 ? -size * 0.35 : size * 0.35
                    )
                    // Next-Gen SF Symbols Effects
                    .symbolEffect(
                        .wiggle.counterClockwise.byLayer,
                        options: .repeat(.periodic(delay: 0.2 + Double(index) * 0.1))
                    )
                    .symbolEffect(.breathe, isActive: isPulsing)
                    .symbolEffect(.bounce.up, value: isBlinking)
                    .contentTransition(
                        .symbolEffect(
                            .replace.magic(fallback: .upUp.byLayer),
                            options: .repeat(.periodic(delay: 0.1))
                        )
                    )
            }
        }
        .opacity(faceModel.profile.geometry.eyeLeft.squint > 0.5 ? 1.0 : 0.6)
    }
    
    // MARK: - Face Features
    
    @ViewBuilder
    private func faceFeatures(size: CGFloat) -> some View {
        VStack(spacing: size * 0.08) {
            // Eyes with SF Symbols
            HStack(spacing: size * 0.15) {
                // Left Eye
                eyeSymbol
                    .symbolEffect(
                        .wiggle.left.byLayer,
                        options: .repeat(.periodic(delay: 0.1))
                    )
                
                // Right Eye
                eyeSymbol
                    .symbolEffect(
                        .wiggle.right.byLayer,
                        options: .repeat(.periodic(delay: 0.1))
                    )
            }
            .font(.system(size: size * 0.12))
            .foregroundStyle(Color(hex: faceModel.profile.appearance.colors.primary))
            .symbolEffect(.scale, value: isBlinking)
            .offset(y: -size * 0.05)
            
            // Nose (SF Symbol)
            Image(systemName: "diamond.fill")
                .font(.system(size: size * 0.05))
                .foregroundStyle(Color(hex: faceModel.profile.appearance.colors.primary))
                .symbolEffect(
                    .wiggle.down.byLayer,
                    options: .repeat(.periodic(delay: 0.1))
                )
                .offset(y: -size * 0.08)
            
            // Mouth with Lip Sync
            mouthSymbol(size: size)
                .offset(y: -size * 0.05)
        }
    }
    
    // MARK: - Eye Symbol (Responsive to Emotion)
    
    @ViewBuilder
    private var eyeSymbol: some View {
        Group {
            if isBlinking {
                Image(systemName: "minus")
                    .symbolEffect(.disappear)
            } else {
                switch currentEmotion {
                case "HAPPY", "EXCITED":
                    Image(systemName: "circle.fill")
                        .symbolEffect(.pulse)
                case "SAD":
                    Image(systemName: "circle")
                        .symbolEffect(.breathe)
                case "SURPRISED":
                    Image(systemName: "circle.circle.fill")
                        .symbolEffect(.bounce)
                case "ANGRY":
                    Image(systemName: "triangle.fill")
                        .symbolEffect(.wiggle.clockwise)
                default:
                    Image(systemName: "circle.fill")
                }
            }
        }
    }
    
    // MARK: - Mouth Symbol (Responsive to Speech)
    
    @ViewBuilder
    private func mouthSymbol(size: CGFloat) -> some View {
        let openAmount = CGFloat(speechManager.audioLevel)
        let smile = faceModel.profile.geometry.mouth.smile
        
        Group {
            if openAmount > 0.3 {
                // Talking (Open mouth)
                Image(systemName: "oval")
                    .font(.system(size: size * 0.15))
                    .foregroundStyle(Color(hex: faceModel.profile.appearance.colors.primary))
                    .symbolEffect(
                        .wiggle.right.byLayer,
                        options: .repeat(.periodic(delay: 1.0))
                    )
                    .scaleEffect(x: 1.0, y: 0.5 + openAmount)
            } else if smile > 0.3 {
                // Smiling
                Image(systemName: "chevron.up")
                    .font(.system(size: size * 0.12))
                    .foregroundStyle(Color(hex: faceModel.profile.appearance.colors.primary))
                    .symbolEffect(.breathe)
                    .rotationEffect(.degrees(180))
            } else if smile < -0.3 {
                // Frowning
                Image(systemName: "chevron.down")
                    .font(.system(size: size * 0.12))
                    .foregroundStyle(Color(hex: faceModel.profile.appearance.colors.primary))
                    .symbolEffect(.breathe)
            } else {
                // Neutral
                Image(systemName: "minus")
                    .font(.system(size: size * 0.12))
                    .foregroundStyle(Color(hex: faceModel.profile.appearance.colors.primary))
            }
        }
    }
    
    // MARK: - Emotion Indicator
    
    @ViewBuilder
    private var emotionIndicator: some View {
        Group {
            switch currentEmotion {
            case "HAPPY":
                Image(systemName: "sparkles")
                    .symbolEffect(.wiggle.counterClockwise.byLayer)
            case "SAD":
                Image(systemName: "drop.fill")
                    .symbolEffect(.wiggle.down.byLayer)
            case "EXCITED":
                Image(systemName: "bolt.fill")
                    .symbolEffect(.bounce)
            case "ANGRY":
                Image(systemName: "flame.fill")
                    .symbolEffect(.wiggle.clockwise)
            default:
                Image(systemName: "circle.fill")
                    .symbolEffect(.breathe)
            }
        }
        .font(.system(size: 20))
        .foregroundStyle(Color(hex: faceModel.profile.appearance.colors.primary))
        .opacity(0.7)
    }
}

// MARK: - Emotion-Driven Animation Controller

extension NextGenPCPOSFace {
    /// Updates animation state based on PersonalityEngine emotion
    func updateEmotion(_ emotion: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            currentEmotion = emotion
        }
    }
}

#if DEBUG
struct NextGenPCPOSFace_Previews: PreviewProvider {
    static var previews: some View {
        NextGenPCPOSFace(
            faceModel: PCPOSFaceModel(),
            speechManager: SpeechManager()
        )
        .frame(width: 200, height: 200)
        .background(Color.gray)
    }
}
#endif
