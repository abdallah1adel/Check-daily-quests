import SwiftUI

// MARK: - Complete Disney 12 Principles Animation Engine

/// Comprehensive implementation of all 12 classic Disney animation principles
struct Disney12Principles {
    
    // MARK: - 1. Squash & Stretch (Enhanced 10X)
    
    struct SquashStretch {
        var amount: Double           // 0.0 to 10.0 (10X from original)
        var elasticity: Double = 1.0 // Material stiffness
        var physics: Physics = .standard
        
        enum Physics {
            case standard      // Normal squash/stretch
            case elastic       // Rubber-like
            case rigid         // Metal-like
            case liquid        // Water-like
            case gel           // Jelly-like
        }
        
        var transform: CGAffineTransform {
            let physicsFactor = physics.factor
            let squash = 1.0 + (amount * 0.4 * elasticity * physicsFactor)
            let stretch = 1.0 / squash  // Volume preservation
            return CGAffineTransform(scaleX: squash, y: stretch)
        }
    }
    
    // MARK: - 2. Anticipation
    
    struct Anticipation {
        var direction: Direction
        var magnitude: Double = 1.0
        var duration: TimeInterval = 0.2
        
        enum Direction {
            case up, down, left, right
            case custom(Angle)
        }
        
        var offset: CGSize {
            let distance = magnitude * 10
            switch direction {
            case .up: return CGSize(width: 0, height: distance)
            case .down: return CGSize(width: 0, height: -distance)
            case .left: return CGSize(width: distance, height: 0)
            case .right: return CGSize(width: -distance, height: 0)
            case .custom(let angle):
                return CGSize(
                    width: cos(angle.radians) * distance,
                    height: sin(angle.radians) * distance
                )
            }
        }
        
        var rotation: Angle {
            .degrees(magnitude * 5)
        }
    }
    
    // MARK: - 3. Staging
    
    struct Staging {
        var focusPoint: CGPoint
        var depthLayer: Int        // 0-4 (5 layers)
        var silhouetteClarity: Double = 1.0
        var contrast: Double = 1.0
        
        var opacity: Double {
            // Far layers are more transparent
            1.0 - (Double(depthLayer) * 0.12) * (1.0 - silhouetteClarity)
        }
        
        var scale: CGFloat {
            // Far layers are smaller (perspective)
            1.0 - (CGFloat(depthLayer) * 0.08)
        }
        
        var zIndex: Double {
            Double(4 - depthLayer)
        }
    }
    
    // MARK: - 4. Straight Ahead vs Pose-to-Pose
    
    enum AnimationMode {
        case straightAhead(steps: Int)
        case poseTopose(keyframes: [Keyframe])
        case hybrid(poses: [Keyframe], fluidSections: [Range<Int>])
        
        struct Keyframe {
            var position: Int
            var value: CGFloat  // Animation value at this keyframe
            var easing: EasingFunction
        }
    }
    
    // MARK: - 5. Follow Through & Overlapping Action
    
    struct FollowThrough {
        var parts: [Part]
        var lagFactor: Double = 0.3
        
        struct Part {
            var id: String
            var mass: Double = 1.0
            var drag: Double = 0.1
            var currentVelocity: CGVector = .zero
            var targetPosition: CGPoint
            
            mutating func update(dt: TimeInterval) {
                let displacement = CGVector(
                    dx: targetPosition.x - currentVelocity.dx,
                    dy: targetPosition.y - currentVelocity.dy
                )
                let acceleration = CGVector(
                    dx: displacement.dx / mass - currentVelocity.dx * drag,
                    dy: displacement.dy / mass - currentVelocity.dy * drag
                )
                currentVelocity.dx += acceleration.dx * dt
                currentVelocity.dy += acceleration.dy * dt
            }
        }
    }
    
    // MARK: - 6. Slow In/Slow Out (Ease In/Out)
    
    enum EasingFunction {
        case linear
        case easeIn, easeOut, easeInOut
        case easeInSine, easeOutSine, easeInOutSine
        case easeInQuad, easeOutQuad, easeInOutQuad
        case easeInCubic, easeOutCubic, easeInOutCubic
        case easeInQuart, easeOutQuart, easeInOutQuart
        case easeInQuint, easeOutQuint, easeInOutQuint
        case easeInExpo, easeOutExpo, easeInOutExpo
        case easeInCirc, easeOutCirc, easeInOutCirc
        case easeInBack, easeOutBack, easeInOutBack
        case easeInElastic, easeOutElastic, easeInOutElastic
        case easeInBounce, easeOutBounce, easeInOutBounce
        
        func value(at t: Double) -> Double {
            let t = max(0, min(1, t))
            switch self {
            case .linear: return t
            case .easeIn: return t * t
            case .easeOut: return t * (2 - t)
            case .easeInOut: return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t
            case .easeInSine: return 1 - cos(t * .pi / 2)
            case .easeOutSine: return sin(t * .pi / 2)
            case .easeInOutSine: return -(cos(.pi * t) - 1) / 2
            case .easeInQuad: return t * t
            case .easeOutQuad: return 1 - (1 - t) * (1 - t)
            case .easeInOutQuad: return t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
            case .easeInCubic: return t * t * t
            case .easeOutCubic: return 1 - pow(1 - t, 3)
            case .easeInOutCubic: return t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
            case .easeInQuart: return t * t * t * t
            case .easeOutQuart: return 1 - pow(1 - t, 4)
            case .easeInOutQuart: return t < 0.5 ? 8 * t * t * t * t : 1 - pow(-2 * t + 2, 4) / 2
            case .easeInQuint: return t * t * t * t * t
            case .easeOutQuint: return 1 - pow(1 - t, 5)
            case .easeInOutQuint: return t < 0.5 ? 16 * t * t * t * t * t : 1 - pow(-2 * t + 2, 5) / 2
            case .easeInExpo: return t == 0 ? 0 : pow(2, 10 * t - 10)
            case .easeOutExpo: return t == 1 ? 1 : 1 - pow(2, -10 * t)
            case .easeInOutExpo:
                if t == 0 { return 0 }
                if t == 1 { return 1 }
                return t < 0.5 ? pow(2, 20 * t - 10) / 2 : (2 - pow(2, -20 * t + 10)) / 2
            case .easeInCirc: return 1 - sqrt(1 - pow(t, 2))
            case .easeOutCirc: return sqrt(1 - pow(t - 1, 2))
            case .easeInOutCirc:
                return t < 0.5 ? (1 - sqrt(1 - pow(2 * t, 2))) / 2 : (sqrt(1 - pow(-2 * t + 2, 2)) + 1) / 2
            case .easeInBack:
                let c1 = 1.70158
                let c3 = c1 + 1
                return c3 * t * t * t - c1 * t * t
            case .easeOutBack:
                let c1 = 1.70158
                let c3 = c1 + 1
                return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2)
            case .easeInOutBack:
                let c1 = 1.70158
                let c2 = c1 * 1.525
                return t < 0.5 ? (pow(2 * t, 2) * ((c2 + 1) * 2 * t - c2)) / 2 :
                    (pow(2 * t - 2, 2) * ((c2 + 1) * (t * 2 - 2) + c2) + 2) / 2
            case .easeInElastic:
                let c4 = (2 * Double.pi) / 3
                if t == 0 { return 0 }
                if t == 1 { return 1 }
                return -pow(2, 10 * t - 10) * sin((t * 10 - 10.75) * c4)
            case .easeOutElastic:
                let c4 = (2 * Double.pi) / 3
                if t == 0 { return 0 }
                if t == 1 { return 1 }
                return pow(2, -10 * t) * sin((t * 10 - 0.75) * c4) + 1
            case .easeInOutElastic:
                let c5 = (2 * .pi) / 4.5
                if t == 0 { return 0 }
                if t == 1 { return 1 }
                return t < 0.5 ?
                    -(pow(2, 20 * t - 10) * sin((20 * t - 11.125) * c5)) / 2 :
                    (pow(2, -20 * t + 10) * sin((20 * t - 11.125) * c5)) / 2 + 1
            case .easeInBounce: return 1 - EasingFunction.easeOutBounce.value(at: 1 - t)
            case .easeOutBounce:
                let n1 = 7.5625
                let d1 = 2.75
                if t < 1 / d1 {
                    return n1 * t * t
                } else if t < 2 / d1 {
                    let t2 = t - 1.5 / d1
                    return n1 * t2 * t2 + 0.75
                } else if t < 2.5 / d1 {
                    let t2 = t - 2.25 / d1
                    return n1 * t2 * t2 + 0.9375
                } else {
                    let t2 = t - 2.625 / d1
                    return n1 * t2 * t2 + 0.984375
                }
            case .easeInOutBounce:
                return t < 0.5 ?
                    (1 - EasingFunction.easeOutBounce.value(at: 1 - 2 * t)) / 2 :
                    (1 + EasingFunction.easeOutBounce.value(at: 2 * t - 1)) / 2
            }
        }
    }
    
    // MARK: - 7. Arcs
    
    struct ArcMotion {
        var startPoint: CGPoint
        var endPoint: CGPoint
        var controlPoint: CGPoint?
        var arcHeight: CGFloat = 50
        
        var bezierPath: Path {
            var path = Path()
            path.move(to: startPoint)
            
            if let control = controlPoint {
                path.addQuadCurve(to: endPoint, control: control)
            } else {
                // Auto-generate arc control point
                let midPoint = CGPoint(
                    x: (startPoint.x + endPoint.x) / 2,
                    y: (startPoint.y + endPoint.y) / 2
                )
                let controlY = midPoint.y - arcHeight
                path.addQuadCurve(to: endPoint, control: CGPoint(x: midPoint.x, y: controlY))
            }
            
            return path
        }
        
        func position(at t: Double) -> CGPoint {
            let control = controlPoint ?? CGPoint(
                x: (startPoint.x + endPoint.x) / 2,
                y: (startPoint.y + endPoint.y) / 2 - arcHeight
            )
            
            let t = max(0, min(1, t))
            let x = pow(1 - t, 2) * startPoint.x + 2 * (1 - t) * t * control.x + pow(t, 2) * endPoint.x
            let y = pow(1 - t, 2) * startPoint.y + 2 * (1 - t) * t * control.y + pow(t, 2) * endPoint.y
            
            return CGPoint(x: x, y: y)
        }
    }
    
    // MARK: - 8. Secondary Action
    
    struct SecondaryAction {
        var mainAction: Animation
        var supportingActions: [SupportingAction]
        
        struct SupportingAction {
            var delay: TimeInterval
            var amplitude: Double
            var animation: Animation
        }
    }
    
    // MARK: - 9. Timing
    
    struct Timing {
        // var frameRate: Int = 60
        var bpm: Double? // Musical synchronization
        var rhythm: Rhythm = .regular
        
        enum Rhythm {
            case regular
            case syncopated
            case crescendo
            case diminuendo
            case staccato
            case legato
        }
        
        func frameDuration(at frame: Int) -> TimeInterval {
            switch rhythm {
            case .regular: return 1.0 / 60.0
            case .syncopated: return frame % 2 == 0 ? 1.0 / 45.0 : 1.0 / 75.0
            case .crescendo: return (1.0 / 60.0) * (1.0 - Double(frame) / 100.0 * 0.5)
            case .diminuendo: return (1.0 / 60.0) * (1.0 + Double(frame) / 100.0 * 0.5)
            case .staccato: return 1.0 / 90.0
            case .legato: return 1.0 / 30.0
            }
        }
    }
    
    // MARK: - 10. Exaggeration
    
    struct Exaggeration {
        var factor: Double = 2.0  // 1.0 = realistic, 10.0 = extreme cartoon
        var mode: Mode = .proportional
        
        enum Mode {
            case proportional  // All features scale equally
            case selective     // Only specific features
            case caricature    // Emphasize distinctive features
        }
        
        func amplify(_ value: Double) -> Double {
            value * factor
        }
        
        func amplify(_ size: CGSize) -> CGSize {
            CGSize(width: size.width * factor, height: size.height * factor)
        }
        
        func amplify(_ angle: Angle) -> Angle {
            .degrees(angle.degrees * factor)
        }
    }
    
    // MARK: - 11. Solid Drawing
    
    struct SolidDrawing {
        var volume: Double = 1.0
        var perspective: Perspective = .none
        var formAwareness: Bool = true
        
        enum Perspective {
            case none
            case onePoint(vanishingPoint: CGPoint)
            case twoPoint(vanishing1: CGPoint, vanishing2: CGPoint)
            case threePoint(vanishing1: CGPoint, vanishing2: CGPoint, vanishing3: CGPoint)
        }
        
        func perspectiveScale(at depth: Double) -> CGFloat {
            switch perspective {
            case .none:
                return 1.0
            case .onePoint:
                return CGFloat(1.0 / (1.0 + depth * 0.5))
            case .twoPoint:
                return CGFloat(1.0 / (1.0 + depth * 0.3))
            case .threePoint:
                return CGFloat(1.0 / (1.0 + depth * 0.2))
            }
        }
    }
    
    // MARK: - 12. Appeal
    
    struct Appeal {
        var personality: Personality
        var charisma: Double = 1.0
        var uniqueness: Double = 1.0
        
        enum Personality {
            case cheerful, serious, playful, mysterious
            case energetic, calm, quirky, elegant
            case confident, shy, bold, gentle
        }
        
        var emotionalResonance: Double {
            charisma * uniqueness
        }
        
        func colorPalette() -> [Color] {
            switch personality {
            case .cheerful: return [.yellow, .orange, .pink]
            case .serious: return [.blue, .gray, .black]
            case .playful: return [.purple, .green, .cyan]
            case .mysterious: return [.indigo, .purple, .black]
            case .energetic: return [.red, .orange, .yellow]
            case .calm: return [.blue, .cyan, .mint]
            case .quirky: return [.pink, .purple, .green]
            case .elegant: return [.white, .gray, .gold]
            case .confident: return [.red, .black, .gold]
            case .shy: return [.pink, .white, .blue]
            case .bold: return [.red, .black, .white]
            case .gentle: return [.pink, .white, .cyan]
            }
        }
    }
}

// MARK: - Helper Extensions

extension Disney12Principles.SquashStretch.Physics {
    var factor: Double {
        switch self {
        case .standard: return 1.0
        case .elastic: return 1.5
        case .rigid: return 0.3
        case .liquid: return 2.0
        case .gel: return 1.8
        }
    }
}

extension Color {
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
}
