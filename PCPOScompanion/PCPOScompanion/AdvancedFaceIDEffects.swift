import SwiftUI

// MARK: - Advanced Face ID Symbol Effects System
// Massive expansion of symbol effects with dynamic variables

struct AdvancedFaceIDEffects {
    
    // MARK: - Wiggle Variations (100+ Combinations)
    
    static let wiggleAngles: [Double] = [
        3.0, 5.0, 7.0, 11.0, 13.0, 17.0, 19.0, 23.0, 29.0, 31.0,
        37.0, 41.0, 43.0, 47.0, 53.0, 59.0, 61.0, 67.0, 71.0, 73.0,
        79.0, 83.0, 89.0, 97.0, 101.0, 103.0, 107.0, 109.0, 113.0, 127.0,
        131.0, 137.0, 139.0, 149.0, 151.0, 157.0, 163.0, 167.0, 173.0, 179.0,
        181.0, 191.0, 193.0, 197.0, 199.0, 211.0, 223.0, 227.0, 229.0, 233.0,
        239.0, 241.0, 251.0, 257.0, 263.0, 269.0, 271.0, 277.0, 281.0, 283.0
    ]
    
    static let wiggleDelays: [Double] = [
        0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5,
        0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 1.0
    ]
    
    // MARK: - Dynamic Effect Generator
    
    static func generateWiggleEffect(intensity: Double, index: Int) -> some View {
        let angleIndex = Int(intensity * Double(wiggleAngles.count - 1))
        let delayIndex = Int((1.0 - intensity) * Double(wiggleDelays.count - 1))
        
        let angle = wiggleAngles[min(angleIndex, wiggleAngles.count - 1)]
        let delay = wiggleDelays[min(delayIndex, wiggleDelays.count - 1)]
        
        return EmptyView()
            .symbolEffect(
                .wiggle.custom(angle: .degrees(angle)).byLayer,
                options: .repeat(.periodic(delay: delay))
            )
    }
    
    // MARK: - Scale Variations
    
    static let scaleDirections: [(up: Bool, intensity: Double)] = [
        (true, 0.1), (true, 0.2), (true, 0.3), (true, 0.4), (true, 0.5),
        (false, 0.1), (false, 0.2), (false, 0.3), (false, 0.4), (false, 0.5)
    ]
    
    // MARK: - Rotation Speeds
    
    static let rotationSpeeds: [Double] = [
        0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0, 4.0
    ]
    
    // MARK: - Composite Effect Builder
    
    static func buildCompositeEffect(
        for part: FacePart,
        intensity: Double,
        isActive: Bool
    ) -> [SymbolEffectModifier] {
        var effects: [SymbolEffectModifier] = []
        
        // Base wiggle
        effects.append(.wiggle(
            angle: .degrees(wiggleAngles[Int(intensity * Double(wiggleAngles.count - 1))]),
            delay: wiggleDelays[Int((1.0 - intensity) * Double(wiggleDelays.count - 1))]
        ))
        
        // Pulse
        if isActive {
            effects.append(.pulse(speed: intensity))
        }
        
        // Bounce
        effects.append(.bounce(intensity: intensity))
        
        // Variable color
        if intensity > 0.5 {
            effects.append(.variableColor(mode: .iterative))
        }
        
        // Breathe
        effects.append(.breathe(speed: 0.5 + intensity))
        
        return effects
    }
}

// MARK: - Face Part Definition

enum FacePart: String, CaseIterable {
    case leftEye
    case rightEye
    case nose
    case mouth
    case brackets
    case emotionIndicator
}

// MARK: - Symbol Effect Modifier

enum SymbolEffectModifier {
    case wiggle(angle: Angle, delay: Double)
    case pulse(speed: Double)
    case bounce(intensity: Double)
    case scale(up: Bool, intensity: Double)
    case variableColor(mode: VariableColorMode)
    case breathe(speed: Double)
    case rotate(speed: Double)
    
    enum VariableColorMode {
        case iterative
        case cumulative
        case reversing
    }
}

// MARK: - Individual Part Controller

@Observable
class FacePartController {
    var leftEyeOffset: CGSize = .zero
    var leftEyeRotation: Angle = .zero
    var leftEyeScale: CGFloat = 1.0
    var leftEyeEffects: [SymbolEffectModifier] = []
    
    var rightEyeOffset: CGSize = .zero
    var rightEyeRotation: Angle = .zero
    var rightEyeScale: CGFloat = 1.0
    var rightEyeEffects: [SymbolEffectModifier] = []
    
    var noseOffset: CGSize = .zero
    var noseRotation: Angle = .zero
    var noseScale: CGFloat = 1.0
    
    var mouthOffset: CGSize = .zero
    var mouthRotation: Angle = .zero
    var mouthScale: CGFloat = 1.0
    
    var bracketsMorphProgress: Double = 0.0
    var bracketsRotation: Angle = .zero
    
    // MARK: - Dynamic Movement Generator
    
    func startContinuousMovement(intensity: Double) {
        // Left eye - horizontal emphasis
        Task {
            while true {
                try? await Task.sleep(for: .seconds(Double.random(in: 1...3)))
                await animateLeftEye(intensity: intensity)
            }
        }
        
        // Right eye - vertical emphasis
        Task {
            while true {
                try? await Task.sleep(for: .seconds(Double.random(in: 1...3)))
                await animateRightEye(intensity: intensity)
            }
        }
        
        // Nose - subtle wiggle
        Task {
            while true {
                try? await Task.sleep(for: .seconds(Double.random(in: 2...3)))
                await animateNose(intensity: intensity)
            }
        }
    }
    
    @MainActor
    private func animateLeftEye(intensity: Double) {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            leftEyeOffset = CGSize(
                width: Double.random(in: -5...5) * intensity,
                height: Double.random(in: -3...3) * intensity
            )
            leftEyeRotation = .degrees(Double.random(in: -15...15) * intensity)
            leftEyeScale = 1.0 + Double.random(in: -0.2...0.3) * intensity
        }
    }
    
    @MainActor
    private func animateRightEye(intensity: Double) {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            rightEyeOffset = CGSize(
                width: Double.random(in: -5...5) * intensity,
                height: Double.random(in: -3...3) * intensity
            )
            rightEyeRotation = .degrees(Double.random(in: -15...15) * intensity)
            rightEyeScale = 1.0 + Double.random(in: -0.2...0.3) * intensity
        }
    }
    
    @MainActor
    private func animateNose(intensity: Double) {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
            noseRotation = .degrees(Double.random(in: -9...9) * intensity)
            noseScale = 0.88 + Double.random(in: 0...0.27) * intensity
        }
    }
    
    // MARK: - Brackets to Circle Morphing
    
    @MainActor
    func morphBracketsToCircle() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            bracketsMorphProgress = 1.0
        }
        
        // Start rotation
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            bracketsRotation = .degrees(360)
        }
    }
    
    @MainActor
    func morphCircleToBrackets() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
            bracketsMorphProgress = 0.0
            bracketsRotation = .zero
        }
    }
}
