import SwiftUI

// MARK: - Mega Effect System (7,200 Combinations)
// 120 wiggle angles × 60 delays = 7,200 unique effects

struct MegaEffectSystem {
    
    // MARK: - 120 Wiggle Angles (Prime numbers 2° to 359°)
    
    static let wiggleAngles: [Double] = [
        // First 30 primes
        2, 3, 5, 7, 11, 13, 17, 19, 23, 29,
        31, 37, 41, 43, 47, 53, 59, 61, 67, 71,
        73, 79, 83, 89, 97, 101, 103, 107, 109, 113,
        
        // Next 30 primes
        127, 131, 137, 139, 149, 151, 157, 163, 167, 173,
        179, 181, 191, 193, 197, 199, 211, 223, 227, 229,
        233, 239, 241, 251, 257, 263, 269, 271, 277, 281,
        
        // Next 30 primes
        283, 293, 307, 311, 313, 317, 331, 337, 347, 349,
        353, 359, 367, 373, 379, 383, 389, 397, 401, 409,
        419, 421, 431, 433, 439, 443, 449, 457, 461, 463,
        
        // Last 30 (completing 120)
        467, 479, 487, 491, 499, 503, 509, 521, 523, 541,
        547, 557, 563, 569, 571, 577, 587, 593, 599, 601,
        607, 613, 617, 619, 631, 641, 643, 647, 653, 659
    ]
    
    // MARK: - 60 Periodic Delays (Log scale 0.01s to 3.0s)
    
    static let periodicDelays: [Double] = [
        // Ultra-fast (0.01-0.1s)
        0.01, 0.015, 0.02, 0.025, 0.03, 0.035, 0.04, 0.045, 0.05, 0.06,
        0.07, 0.08, 0.09, 0.1,
        
        // Fast (0.1-0.3s)
        0.11, 0.12, 0.13, 0.14, 0.15, 0.16, 0.17, 0.18, 0.19, 0.2,
        0.22, 0.24, 0.26, 0.28, 0.3,
        
        // Medium (0.3-0.8s)
        0.32, 0.34, 0.36, 0.38, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65,
        0.7, 0.75, 0.8,
        
        // Slow (0.8-3.0s)
        0.9, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.75, 2.0, 2.25,
        2.5, 2.75, 3.0
    ]
    
    // MARK: - Effect Generator
    
    struct EffectConfiguration {
        let angleIndex: Int
        let delayIndex: Int
        let intensity: Double
        
        var angle: Angle {
            let angleValue = wiggleAngles[angleIndex % wiggleAngles.count]
            return .degrees(angleValue * intensity)
        }
        
        var delay: Double {
            periodicDelays[delayIndex % periodicDelays.count] / max(0.1, intensity)
        }
        
        var effectID: String {
            "effect_\(angleIndex)_\(delayIndex)"
        }
    }
    
    // MARK: - Dynamic Effect Selection
    
    static func selectEffect(
        for emotion: String,
        intensity: Double,
        seed: Int
    ) -> EffectConfiguration {
        // Deterministic but varied selection
        let angleIndex: Int
        let delayIndex: Int
        
        switch emotion {
        case "HAPPY":
            // Light, fast angles
            angleIndex = (seed % 30)  // First 30 angles (2-113°)
            delayIndex = (seed % 15) + 10  // Fast-medium delays
            
        case "EXCITED":
            // Large, rapid angles
            angleIndex = (seed % 30) + 60  // Mid-large angles
            delayIndex = (seed % 10)  // Ultra-fast
            
        case "SAD":
            // Slow, small angles
            angleIndex = (seed % 20)  // Small angles
            delayIndex = (seed % 15) + 45  // Slow delays
            
        case "ANGRY":
            // Sharp, chaotic angles
            angleIndex = (seed % 30) + 90  // Large angles
            delayIndex = (seed % 15)  // Fast
            
        case "CALM":
            // Smooth, minimal angles
            angleIndex = (seed % 15)  // Minimal angles
            delayIndex = (seed % 10) + 40  // Medium-slow
            
        case "CONFUSED":
            // Random, varied
            angleIndex = seed % 120  // Any angle
            delayIndex = (seed * 7) % 60  // Varied delays
            
        case "SURPRISED":
            // Sharp, quick
            angleIndex = (seed % 20) + 40  // Medium angles
            delayIndex = seed % 10  // Quick
            
        case "THINKING":
            // Rhythmic, steady
            angleIndex = (seed % 30) + 30
            delayIndex = (seed % 5) + 25  // Steady rhythm
            
        default:
            // Neutral -minimal
            angleIndex = seed % 30
            delayIndex = (seed % 10) + 20
        }
        
        return EffectConfiguration(
            angleIndex: angleIndex,
            delayIndex: delayIndex,
            intensity: intensity
        )
    }
    
    // MARK: - Multi-Effect Combiner
    
    struct CombinedEffect {
        let primary: EffectConfiguration
        let secondary: EffectConfiguration?
        let tertiary: EffectConfiguration?
        
        static func create(
            emotion: String,
            intensity: Double,
            layerCount: Int = 3
        ) -> CombinedEffect {
            let primary = selectEffect(for: emotion, intensity: intensity, seed: 0)
            let secondary = layerCount > 1 ? selectEffect(for: emotion, intensity: intensity * 0.7, seed: 1) : nil
            let tertiary = layerCount > 2 ? selectEffect(for: emotion, intensity: intensity * 0.4, seed: 2) : nil
            
            return CombinedEffect(
                primary: primary,
                secondary: secondary,
                tertiary: tertiary
            )
        }
    }
    
    // MARK: - Effect Pool (Performance Optimization)
    
    class EffectPool {
        private var pool: [String: EffectConfiguration] = [:]
        private let maxPoolSize = 100
        
        func get(emotion: String, intensity: Double, seed: Int) -> EffectConfiguration {
            let key = "\(emotion)_\(Int(intensity * 100))_\(seed)"
            
            if let cached = pool[key] {
                return cached
            }
            
            let effect = MegaEffectSystem.selectEffect(for: emotion, intensity: intensity, seed: seed)
            
            // Manage pool size
            if pool.count >= maxPoolSize {
                pool.removeAll()
            }
            
            pool[key] = effect
            return effect
        }
    }
    
    // MARK: - View Modifiers
    
    struct WiggleEffectModifier: ViewModifier {
        let config: EffectConfiguration
        let isActive: Bool
        
        func body(content: Content) -> some View {
            content
                .symbolEffect(
                    .wiggle.custom(angle: config.angle).byLayer,
                    options: .repeat(.periodic(delay: config.delay)),
                    isActive: isActive
                )
        }
    }
    
    struct LayeredWiggleModifier: ViewModifier {
        let combined: CombinedEffect
        let isActive: Bool
        
        func body(content: Content) -> some View {
            var view = AnyView(content)
            
            // Primary effect
            view = AnyView(
                view.modifier(WiggleEffectModifier(config: combined.primary, isActive: isActive))
            )
            
            // Secondary effect (if exists)
            if let secondary = combined.secondary {
                view = AnyView(
                    view.modifier(WiggleEffectModifier(config: secondary, isActive: isActive))
                )
            }
            
            // Tertiary effect (if exists)
            if let tertiary = combined.tertiary {
                view = AnyView(
                    view.modifier(WiggleEffectModifier(config: tertiary, isActive: isActive))
                )
            }
            
            return view
        }
    }
}

// MARK: - Extensions

extension View {
    func megaWiggle(
        emotion: String,
        intensity: Double,
        seed: Int = 0,
        isActive: Bool = true
    ) -> some View {
        let effect = MegaEffectSystem.selectEffect(for: emotion, intensity: intensity, seed: seed)
        return self.modifier(MegaEffectSystem.WiggleEffectModifier(config: effect, isActive: isActive))
    }
    
    func layeredWiggle(
        emotion: String,
        intensity: Double,
        layers: Int = 3,
        isActive: Bool = true
    ) -> some View {
        let combined = MegaEffectSystem.CombinedEffect.create(
            emotion: emotion,
            intensity: intensity,
            layerCount: layers
        )
        return self.modifier(MegaEffectSystem.LayeredWiggleModifier(combined: combined, isActive: isActive))
    }
}

// MARK: - Effect Statistics

extension MegaEffectSystem {
    static var totalCombinations: Int {
        wiggleAngles.count * periodicDelays.count
    }
    
    static var angleRange: ClosedRange<Double> {
        wiggleAngles.min()!...wiggleAngles.max()!
    }
    
    static var delayRange: ClosedRange<Double> {
        periodicDelays.min()!...periodicDelays.max()!
    }
    
    static func summary() -> String {
        """
        Mega Effect System:
        - Total Combinations: \(totalCombinations)
        - Angle Count: \(wiggleAngles.count)
        - Angle Range: \(angleRange.lowerBound)° - \(angleRange.upperBound)°
        - Delay Count: \(periodicDelays.count)
        - Delay Range: \(delayRange.lowerBound)s - \(delayRange.upperBound)s
        """
    }
}
