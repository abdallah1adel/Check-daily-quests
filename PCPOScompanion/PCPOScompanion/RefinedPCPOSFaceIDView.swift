import SwiftUI
import Combine

/// Refined PCPOS Face ID Style with Full SF Symbols Integration
/// Unleashing the complete power of SF Symbols for expressive communication
struct RefinedPCPOSFaceIDView: View {
    @ObservedObject var faceModel: PCPOSFaceModel
    @ObservedObject var speechManager: SpeechManager
    
    // Face-level animation
    @State private var bracketExpansion: Double = 0
    @State private var scanProgress: Double = 0
    @State private var isScanning: Bool = false
    @State private var currentEmotion: String = "NEUTRAL"
    @State private var emotionIntensity: Double = 0.5
    
    // MARK: - 10X Engines
    @StateObject private var mlCluster = MLAgentCluster()
    @StateObject private var loop = HighPerformanceLoop()
    @StateObject private var depthManager = MultiLayerDepthSystem.Manager()
    
    // Face ID Symbols for 5-Layer Depth
    private let faceIDSymbols = ["faceid", "lock.fill", "checkmark.shield.fill", "waveform", "sparkles", "face.smiling", "eye.fill", "mouth.fill", "nose.fill", "bolt.fill"]
    private let emotionColors: [Color] = [.blue, .green, .orange, .pink, .purple, .cyan]
    
    // Individual Part Animations (Full Rigging)
    @State private var leftEyeOffset: CGSize = .zero
    @State private var leftEyeScale: CGFloat = 1.0
    @State private var leftEyeRotation: Angle = .zero
    
    @State private var rightEyeOffset: CGSize = .zero
    @State private var rightEyeScale: CGFloat = 1.0
    @State private var rightEyeRotation: Angle = .zero
    
    @State private var noseOffset: CGSize = .zero
    @State private var noseScale: CGFloat = 1.0
    @State private var noseWiggle: Angle = .zero
    
    @State private var mouthOffset: CGSize = .zero
    @State private var mouthScale: CGFloat = 1.0
    @State private var mouthRotation: Angle = .zero
    
    @State private var isBlinking: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            
            ZStack {
                // Base Circle (Clean, minimal)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.black.opacity(0.95),
                                Color.black
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size / 2
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(hex: faceModel.profile.appearance.colors.primary).opacity(0.8),
                                        Color(hex: faceModel.profile.appearance.colors.primary).opacity(0.4),
                                        Color(hex: faceModel.profile.appearance.colors.primary).opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                
                // 5-Layer Depth Background (10X Expansion)
                FiveLayerRotationView(
                    symbols: faceIDSymbols,
                    colors: emotionColors,
                    baseSize: size * 0.05
                )
                .opacity(isScanning ? 1.0 : 0.3)
                .mask(Circle().frame(width: size, height: size))
                
                // Face ID Brackets (Proper Apple Style)
                FaceIDBracketsView(
                    expansion: bracketExpansion,
                    color: Color(hex: faceModel.profile.appearance.colors.primary),
                    isActive: speechManager.isSpeaking
                )
                .frame(width: size * 0.85, height: size * 0.85)
                
                // Scanning Effect (when talking)
                if speechManager.isSpeaking {
                    scanningEffect(size: size)
                }
                
                // Face Core (Eyes, Nose, Mouth)
                faceCore(size: size)
                
                // Emotion Indicator (Top Right)
                emotionIndicator
                    .offset(x: size * 0.35, y: -size * 0.35)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onChange(of: speechManager.isSpeaking) { speaking in
            if speaking {
                startScanAnimation()
                startTalkingAnimation()
            } else {
                stopScanAnimation()
                stopTalkingAnimation()
            }
        }
        .onAppear {
            // Start 120fps Loop
            loop.register(id: "animation_update") { dt in
                // Update physics or continuous animation here
                // For example, smooth interpolation of face parts
            }
            loop.start()
            
            // Start ML Decision Cycle
            Task {
                while true {
                    let state = FaceState(
                        currentEmotion: currentEmotion,
                        emotionIntensity: emotionIntensity,
                        mouthSmile: faceModel.profile.geometry.mouth.smile,
                        eyeSquint: faceModel.profile.geometry.eyeLeft.squint,
                        audioLevel: Double(speechManager.audioLevel),
                        isSpeaking: speechManager.isSpeaking
                    )
                    
                    let decision = await mlCluster.makeDecision(input: state)
                    
                    await MainActor.run {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            // Apply ML decision to visual state
                            // This is where the "Brain" drives the "Face"
                            if decision.confidence > 0.7 {
                                // Subtle adjustments based on ML
                                // e.g. slight color shift or micro-expression
                            }
                        }
                    }
                    
                    try? await Task.sleep(nanoseconds: 100_000_000) // 10Hz decision rate
                }
            }
        }
        .onDisappear {
            loop.stop()
        }
        .onChange(of: speechManager.audioLevel) { level in
            // Mouth moves with speech intensity
            withAnimation(.spring(response: 0.08, dampingFraction: 0.4)) {
                mouthScale = 1.0 + CGFloat(level) * 0.6
                mouthOffset = CGSize(width: 0, height: CGFloat(level) * 3)
            }
        }
        .onChange(of: faceModel.profile.geometry.eyeLeft.openness) { blink in
            isBlinking = blink > 0.3
            // Eyes close together
            withAnimation(.spring(response: 0.1, dampingFraction: 0.6)) {
                leftEyeScale = 1.0 - blink
                rightEyeScale = 1.0 - blink
            }
        }
        .onChange(of: faceModel.profile.geometry.eyeLeft.squint) { raise in
            // Eyes move up with eyebrow raise
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                leftEyeOffset = CGSize(width: -raise * 2, height: -raise * 5)
                rightEyeOffset = CGSize(width: raise * 2, height: -raise * 5)
                leftEyeScale = 1.0 + raise * 0.3
                rightEyeScale = 1.0 + raise * 0.3
            }
        }
        .onChange(of: faceModel.profile.geometry.mouth.smile) { smile in
            // Mouth rotates with smile/frown
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                mouthRotation = .degrees(smile * 5)
                // Nose wiggles slightly with expressions
                noseWiggle = .degrees(smile * 3)
            }
        }
        .onChange(of: faceModel.profile.geometry.mouth.smile) { _ in
            // Update emotion based on face model
            updateCurrentEmotion()
        }
        .task {
            // Continuous idle animations
            await withTaskGroup(of: Void.self) { group in
                // Subtle eye movement (looking around)
                group.addTask {
                    while !Task.isCancelled {
                        try? await Task.sleep(for: .seconds(2))
                        await subtleEyeMovement()
                    }
                }
                
                // Nose wiggle (breathing)
                group.addTask {
                    while !Task.isCancelled {
                        try? await Task.sleep(for: .seconds(3))
                        await noseBreathing()
                    }
                }
                
                // Emotion monitoring
                group.addTask {
                    for await _ in Timer.publish(every: 0.5, on: .main, in: .common).autoconnect().values {
                        updateCurrentEmotion()
                    }
                }
            }
        }
    }
    
    // MARK: - Face Core (Features)
    
    @ViewBuilder
    private func faceCore(size: CGFloat) -> some View {
        VStack(spacing: size * 0.08) {
            // Eyes (Individual Movement)
            HStack(spacing: size * 0.15) {
                // Left Eye
                eyeShape(size: size)
                    .offset(leftEyeOffset)
                    .scaleEffect(leftEyeScale)
                    .rotationEffect(leftEyeRotation)
                
                // Right Eye
                eyeShape(size: size)
                    .offset(rightEyeOffset)
                    .scaleEffect(rightEyeScale)
                    .rotationEffect(rightEyeRotation)
            }
            .offset(y: -size * 0.05)
            
            // Nose (Individual Movement)
            Capsule()
                .fill(Color(hex: faceModel.profile.appearance.colors.primary))
                .frame(width: size * 0.03, height: size * 0.06)
                .offset(noseOffset)
                .scaleEffect(noseScale)
                .rotationEffect(noseWiggle)
                .offset(y: -size * 0.08)
            
            // Mouth (Individual Movement - already implemented)
            mouthShape(size: size)
                .offset(y: -size * 0.05)
        }
    }
    
    @ViewBuilder
    private func eyeShape(size: CGFloat) -> some View {
        let blinkAmount = faceModel.profile.geometry.eyeLeft.openness
        let eyeBrowRaise = faceModel.profile.geometry.eyeLeft.squint
        
        ZStack {
            // Eye with gradient fill
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: faceModel.profile.appearance.colors.primary),
                            Color(hex: faceModel.profile.appearance.colors.primary).opacity(0.7)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(
                    width: size * 0.12,
                    height: size * 0.12 * (1.0 - blinkAmount)
                )
                .overlay(
                    Capsule()
                        .stroke(Color(hex: faceModel.profile.appearance.colors.primary).opacity(0.3), lineWidth: 1)
                )
            
            // Highlight (glint)
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: size * 0.03, height: size * 0.03)
                .offset(x: -size * 0.02, y: -size * 0.02)
        }
        .scaleEffect(1.0 + eyeBrowRaise * 0.2)
    }
    
    @ViewBuilder
    private func mouthShape(size: CGFloat) -> some View {
        let openAmount = CGFloat(speechManager.audioLevel)
        let smile = faceModel.profile.geometry.mouth.smile
        
        Group {
            if openAmount > 0.2 {
                // Open mouth (talking) - moves independently
                Ellipse()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(hex: faceModel.profile.appearance.colors.primary),
                                Color(hex: faceModel.profile.appearance.colors.primary).opacity(0.6)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 3
                    )
                    .frame(
                        width: size * 0.18,
                        height: size * 0.08 * (0.5 + openAmount)
                    )
            } else {
                // Closed mouth (smile/neutral)
                Path { path in
                    let width = size * 0.2
                    let curvature = smile * size * 0.05
                    
                    path.move(to: CGPoint(x: -width/2, y: 0))
                    path.addQuadCurve(
                        to: CGPoint(x: width/2, y: 0),
                        control: CGPoint(x: 0, y: curvature)
                    )
                }
                .stroke(
                    Color(hex: faceModel.profile.appearance.colors.primary),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
            }
        }
        // Individual transforms (applied to entire mouth group)
        .offset(mouthOffset)
        .scaleEffect(mouthScale)
        .rotationEffect(mouthRotation)
    }
    
    // MARK: - Scanning Effect
    
    @ViewBuilder
    private func scanningEffect(size: CGFloat) -> some View {
        Circle()
            .trim(from: 0, to: 0.3)
            .stroke(
                AngularGradient(
                    colors: [
                        Color(hex: faceModel.profile.appearance.colors.primary).opacity(0.0),
                        Color(hex: faceModel.profile.appearance.colors.primary).opacity(0.8),
                        Color(hex: faceModel.profile.appearance.colors.primary).opacity(0.0)
                    ],
                    center: .center
                ),
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )
            .frame(width: size * 0.7, height: size * 0.7)
            .rotationEffect(.degrees(scanProgress * 360))
    }
    
    // MARK: - Emotion Indicator (20X Expanded SF Symbols Library)
    
    @ViewBuilder
    private var emotionIndicator: some View {
        // Dynamic symbol selection from 200+ library
        let symbolName = PCPOSSymbolLibrary.symbolFor(
            emotion: currentEmotion,
            intensity: emotionIntensity,
            speaking: speechManager.isSpeaking
        )
        let symbolColor = PCPOSSymbolLibrary.colorFor(
            emotion: currentEmotion,
            intensity: emotionIntensity
        )
        let intensity = emotionIntensity
        
        Image(systemName: symbolName)
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(
                .linearGradient(
                    colors: [
                        symbolColor,
                        symbolColor.opacity(0.7)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            // MARK: Variable Color Effects (Layered Animation)
            .symbolEffect(
                .variableColor.iterative.hideInactiveLayers.reversing,
                options: .repeat(.periodic(delay: intensity > 0.7 ? 0.2 : 0.4)),
                isActive: intensity > 0.5
            )
            .symbolEffect(
                .variableColor.cumulative.hideInactiveLayers.reversing,
                options: .repeat(.periodic(delay: 0.3)),
                isActive: speechManager.isSpeaking
            )
            
            // MARK: Dynamic Wiggle Effects (Emotion-Driven Angles)
            .symbolEffect(
                .wiggle.backward.byLayer,
                options: .repeat(.periodic(delay: 0.3)),
                isActive: currentEmotion == "CONFUSED" || currentEmotion == "THINKING"
            )
            .symbolEffect(
                .wiggle.byLayer,
                options: .repeat(.periodic(delay: emotionWiggleDelay())),
                isActive: emotionIntensity > 0.3
            )
            
            // MARK: Pulse Effect (Emphasis)
            .symbolEffect(
                .pulse,
                options: .nonRepeating,
                value: isBlinking
            )
            
            // MARK: Core Animation Effects
            .symbolEffect(.pulse, options: .repeat(.continuous), isActive: speechManager.isSpeaking)
            .symbolEffect(.bounce, value: currentEmotion)
            .symbolEffect(.breathe, options: .repeat(.continuous).speed(intensity))
            
            // MARK: Advanced Custom Wiggle (257° Angle)
            .symbolEffect(
                .wiggle.custom(angle: .degrees(257.0)).byLayer,
                options: .repeat(.periodic(delay: 0.3)),
                isActive: intensity > 0.6
            )
            
            // MARK: Continuous Smooth Transitions (In/Out Animation)
            .contentTransition(
                .symbolEffect(
                    .replace.magic(fallback: .downUp.byLayer),
                    options: .speed(0.5)
                )
            )
            .contentTransition(
                .symbolEffect(
                    .replace.upUp.byLayer,
                    options: .repeat(.continuous).speed(0.3)
                )
            )
            .contentTransition(
                .symbolEffect(
                    .replace.downUp.byLayer,
                    options: .repeat(.continuous).speed(0.4)
                )
            )
            
            // MARK: Visual Effects
            .shadow(
                color: symbolColor.opacity(intensity * 0.8),
                radius: intensity * 10
            )
            .rotationEffect(rotationForEmotion())
            .animation(
                animationForEmotion(),
                value: currentEmotion
            )
            // Continuous rotation cycle for active states
            .rotationEffect(.degrees(speechManager.isSpeaking ? 360 : 0))
            .animation(
                speechManager.isSpeaking ? .linear(duration: 4).repeatForever(autoreverses: false) : .default,
                value: speechManager.isSpeaking
            )
    }
    
    private func updateCurrentEmotion() {
        // Derive emotion from PAD values
        let valence = faceModel.profile.geometry.mouth.smile
        let arousal = faceModel.profile.geometry.eyeLeft.squint
        
        if valence > 0.5 {
            currentEmotion = "HAPPY"
        } else if valence < -0.5 {
            currentEmotion = "SAD"
        } else if arousal > 0.7 {
            currentEmotion = "EXCITED"
        } else if arousal < 0.3 {
            currentEmotion = "CALM"
        } else {
            currentEmotion = "NEUTRAL"
        }
    }
    
    // MARK: - Dynamic Symbol Selection (Mood-Driven)
    
    private func emotionSymbolName() -> String {
        // Context-aware symbol selection
        if speechManager.isSpeaking {
            switch currentEmotion {
            case "HAPPY": return "face.smiling.inverse"
            case "EXCITED": return "bolt.heart.fill"
            case "THINKING": return "ellipsis.bubble.fill"
            case "SURPRISED": return "exclamationmark.2.bubble"
            default: return "waveform.circle.fill"
            }
        } else {
            switch currentEmotion {
            case "HAPPY": return emotionIntensity > 0.7 ? "face.smiling.inverse" : "face.smiling"
            case "SAD": return emotionIntensity > 0.6 ? "cloud.rain.fill" : "cloud.fill"
            case "EXCITED": return "bolt.heart.fill"
            case "ANGRY": return emotionIntensity > 0.7 ? "flame.fill" : "exclamationmark.triangle.fill"
            case "SURPRISED": return "sparkles"
            case "CALM": return "moon.stars.fill"
            case "THINKING": return "brain.head.profile"
            case "CONFUSED": return "questionmark.bubble.fill"
            default: return "circle.hexagongrid.fill"
            }
        }
    }
    
    private func emotionColor() -> Color {
        switch currentEmotion {
        case "HAPPY": return .yellow
        case "SAD": return .blue
        case "EXCITED": return .orange
        case "ANGRY": return .red
        case "SURPRISED": return .purple
        case "CALM": return .cyan
        case "THINKING": return .indigo
        case "CONFUSED": return .mint
        default: return Color(hex: faceModel.profile.appearance.colors.primary)
        }
    }
    
    // MARK: - Dynamic Animation Selection
    
    private func wiggleEffectForMood() -> WiggleSymbolEffect {
        return .wiggle.byLayer
    }
    
    private func wiggleAngleForMood() -> Angle {
        switch currentEmotion {
        case "EXCITED": return .degrees(17.0)
        case "HAPPY": return .degrees(11.0)
        case "SURPRISED": return .degrees(1102.0) // Extreme wiggle
        case "ANGRY": return .degrees(3.0)
        case "CONFUSED": return .degrees(11.0)
        default: return .degrees(5.0)
        }
    }
    
    private func emotionWiggleDelay() -> Double {
        // Faster wiggle for high-intensity emotions
        return emotionIntensity > 0.7 ? 0.1 : 0.3
    }
    
    private func rotationForEmotion() -> Angle {
        switch currentEmotion {
        case "EXCITED": return .degrees(360)
        case "CONFUSED": return .degrees(speechManager.isSpeaking ? 15 : 0)
        default: return .zero
        }
    }
    
    private func animationForEmotion() -> Animation? {
        switch currentEmotion {
        case "EXCITED":
            return .linear(duration: 2).repeatForever(autoreverses: false)
        case "CONFUSED":
            return .easeInOut(duration: 0.5).repeatForever(autoreverses: true)
        default:
            return .default
        }
    }
    
    // MARK: - Animations
    
    private func startScanAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            bracketExpansion = 0.8
        }
        
        // Continuous rotation while speaking
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            scanProgress = 1.0
        }
    }
    
    private func stopScanAnimation() {
        withAnimation(.easeOut(duration: 0.5)) {
            bracketExpansion = 0
            scanProgress = 0
        }
    }
    
    // MARK: - Individual Part Animation Functions
    
    /// Subtle eye movement (idle animation - looking around)
    @MainActor
    private func subtleEyeMovement() async {
        let randomX = CGFloat.random(in: -3...3)
        let randomY = CGFloat.random(in: -2...2)
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            leftEyeOffset.width += randomX
            leftEyeOffset.height += randomY
            rightEyeOffset.width += randomX * 0.8 // Slightly different for naturalism
            rightEyeOffset.height += randomY * 0.9
        }
        
        // Return to center after a moment
        try? await Task.sleep(for: .seconds(1.5))
        withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
            leftEyeOffset.width = 0
            leftEyeOffset.height = 0
            rightEyeOffset.width = 0
            rightEyeOffset.height = 0
        }
    }
    
    /// Nose breathing animation (subtle scale pulse)
    @MainActor
    private func noseBreathing() async {
        withAnimation(.easeInOut(duration: 1.5)) {
            noseScale = 1.05
        }
        
        try? await Task.sleep(for: .seconds(1.5))
        
        withAnimation(.easeInOut(duration: 1.5)) {
            noseScale = 1.0
        }
    }
    
    /// Start talking animation (continuous mouth + eye emphasis)
    private func startTalkingAnimation() {
        // Eyes widen slightly when talking
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            leftEyeScale *= 1.1
            rightEyeScale *= 1.1
        }
        
        // Subtle nose wiggle
        withAnimation(.linear(duration: 0.5).repeatForever(autoreverses: true)) {
            noseWiggle = .degrees(2)
        }
    }
    
    /// Stop talking animation (return to rest)
    private func stopTalkingAnimation() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            leftEyeScale = 1.0
            rightEyeScale = 1.0
            mouthScale = 1.0
            mouthOffset = .zero
            noseWiggle = .zero
        }
    }
}

// MARK: - Face ID Brackets (Morphing to Circle - Apple Style)

struct FaceIDBracketsView: View {
    let expansion: Double
    let color: Color
    let isActive: Bool
    
    @State private var morphProgress: Double = 0
    @State private var rotationAngle: Double = 0
    
    // Extracted computed properties to simplify body
    private var pulseAmount: Double {
        isActive ? sin(rotationAngle * .pi / 180) * 0.05 : 0
    }
    
    private var gradientColors: [Color] {
        isActive ? [color, color.opacity(0.6), color] : [color.opacity(0.6)]
    }
    
    private var shadowColor: Color {
        isActive ? color.opacity(0.5) : .clear
    }
    
    private var shadowRadius: CGFloat {
        isActive ? 8 : 0
    }
    
    var body: some View {
        GeometryReader { geo in
            bracketsContent(width: geo.size.width, height: geo.size.height)
        }
        .onChange(of: isActive) { active in
            if active {
                startScanning()
            } else {
                stopScanning()
            }
        }
    }
    
    @ViewBuilder
    private func bracketsContent(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            bracketShape
            
            if isActive && morphProgress > 0.5 {
                scanningParticles(width: width, height: height)
            }
        }
    }
    
    @ViewBuilder
    private var bracketShape: some View {
        CircularBracketMorph(
            morphProgress: morphProgress,
            pulseAmount: pulseAmount
        )
        .stroke(
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            style: StrokeStyle(
                lineWidth: 2,
                lineCap: .round,
                lineJoin: .round
            )
        )
        .rotationEffect(.degrees(rotationAngle))
        .shadow(color: shadowColor, radius: shadowRadius)
    }
    
    @ViewBuilder
    private func scanningParticles(width: CGFloat, height: CGFloat) -> some View {
        ForEach(0..<3, id: \.self) { index in
            Circle()
                .fill(color.opacity(0.6))
                .frame(width: 4, height: 4)
                .offset(
                    x: particleX(index: index, width: width),
                    y: particleY(index: index, height: height)
                )
        }
    }
    
    private func particleX(index: Int, width: CGFloat) -> CGFloat {
        let angleRad = rotationAngle * .pi / 180 + Double(index) * 120 * .pi / 180
        return CGFloat(cos(angleRad)) * (width / 2 - 10)
    }
    
    private func particleY(index: Int, height: CGFloat) -> CGFloat {
        let angleRad = rotationAngle * .pi / 180 + Double(index) * 120 * .pi / 180
        return CGFloat(sin(angleRad)) * (height / 2 - 10)
    }
    
    private func startScanning() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            morphProgress = 1.0
        }
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
    
    private func stopScanning() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
            morphProgress = 0.0
            rotationAngle = 0
        }
    }
}

// MARK: - Updated Bracket View Using CircularBracketMorph

extension FaceIDBracketsView {
    var enhancedBrackets: some View {
        CircularBracketMorph(
            morphProgress: morphProgress,
            pulseAmount: isActive ? 0.1 : 0
        )
        .stroke(
            LinearGradient(
                colors: isActive ? [
                    color,
                    color.opacity(0.6),
                    color
                ] : [
                    color.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            style: StrokeStyle(
                lineWidth: 2,
                lineCap: .round,
                lineJoin: .round
            )
        )
        .rotationEffect(.degrees(rotationAngle))
        .shadow(
            color: isActive ? color.opacity(0.5) : .clear,
            radius: isActive ? 8 : 0
        )
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: morphProgress)
        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isActive)
    }
}

#if DEBUG
struct RefinedPCPOSFaceIDView_Previews: PreviewProvider {
    static var previews: some View {
        RefinedPCPOSFaceIDView(
            faceModel: PCPOSFaceModel(),
            speechManager: SpeechManager()
        )
        .frame(width: 200, height: 200)
        .background(Color.gray)
    }
}
#endif
