import SwiftUI

// MARK: - Squash & Stretch Animation System

/// Classic animation principles for Face ID
struct SquashStretchAnimation {
    
    // MARK: - Animation States
    
    enum AnimationState {
        case idle
        case anticipation
        case squash
        case stretch
        case settle
    }
    
    // MARK: - Squash & Stretch Parameters
    
    struct Parameters {
        var scaleX: CGFloat = 1.0
        var scaleY: CGFloat = 1.0
        var rotation: Angle = .zero
        var offset: CGSize = .zero
        
        // Classic squash (compressed vertically, expanded horizontally)
        static func squash(amount: Double) -> Parameters {
            Parameters(
                scaleX: 1.0 + CGFloat(amount * 0.4),  // Wider
                scaleY: 1.0 - CGFloat(amount * 0.4),  // Shorter
                rotation: .zero,
                offset: .zero
            )
        }
        
        // Classic stretch (expanded vertically, compressed horizontally)
        static func stretch(amount: Double) -> Parameters {
            Parameters(
                scaleX: 1.0 - CGFloat(amount * 0.3),  // Narrower
                scaleY: 1.0 + CGFloat(amount * 0.5),  // Taller
                rotation: .zero,
                offset: CGSize(width: 0, height: -amount * 5)
            )
        }
        
        // Anticipation (slight pull back before action)
        static func anticipation(direction: Direction) -> Parameters {
            switch direction {
            case .up:
                return Parameters(
                    scaleX: 1.05,
                    scaleY: 0.95,
                    rotation: .zero,
                    offset: CGSize(width: 0, height: 3)
                )
            case .down:
                return Parameters(
                    scaleX: 0.95,
                    scaleY: 1.05,
                    rotation: .zero,
                    offset: CGSize(width: 0, height: -3)
                )
            case .left, .right:
                return Parameters(
                    scaleX: 0.95,
                    scaleY: 1.0,
                    rotation: .degrees(direction == .left ? 5 : -5),
                    offset: CGSize(width: direction == .left ? 3 : -3, height: 0)
                )
            }
        }
        
        // Overshoot (exaggeration before settling)
        static func overshoot(factor: Double) -> Parameters {
            Parameters(
                scaleX: 1.0 + CGFloat(factor * 0.15),
                scaleY: 1.0 + CGFloat(factor * 0.15),
                rotation: .zero,
                offset: .zero
            )
        }
        
        enum Direction {
            case up, down, left, right
        }
    }
    
    // MARK: - Speech Animation (Squash & Stretch)
    
    struct SpeechAnimation {
        let audioLevel: Double
        let phase: Double  // 0.0 to 1.0 cycle
        
        var params: Parameters {
            // Alternate between squash and stretch based on phase
            if phase < 0.5 {
                // Squash phase (mouth opening)
                let progress = phase * 2  // 0.0 → 1.0
                return .squash(amount: audioLevel * progress)
            } else {
                // Stretch phase (mouth closing)
                let progress = (phase - 0.5) * 2  // 0.0 → 1.0
                return .stretch(amount: audioLevel * (1.0 - progress))
            }
        }
    }
    
    // MARK: - Blink Animation (Squash & Stretch)
    
    struct BlinkAnimation {
        let blinkAmount: Double  // 0.0 (open) to 1.0 (closed)
        
        var params: Parameters {
            if blinkAmount < 0.3 {
                // Anticipation (slight stretch before closing)
                return .anticipation(direction: .up)
            } else if blinkAmount < 0.7 {
                // Squash (eye closing)
                let progress = (blinkAmount - 0.3) / 0.4
                return Parameters(
                    scaleX: 1.0 + CGFloat(progress * 0.2),
                    scaleY: 1.0 - CGFloat(progress * 0.8),
                    rotation: .zero,
                    offset: .zero
                )
            } else {
                // Fully closed with slight horizontal stretch
                return Parameters(
                    scaleX: 1.15,
                    scaleY: 0.1,
                    rotation: .zero,
                    offset: .zero
                )
            }
        }
    }
    
    // MARK: - Surprise Animation (Pop!)
    
    struct SurpriseAnimation {
        let intensity: Double
        
        var sequence: [Parameters] {
            [
                .squash(amount: 0.5 * intensity),           // Anticipation
                .overshoot(factor: 1.2 * intensity),        // Pop!
                .overshoot(factor: 0.8 * intensity),        // Bounce back
                Parameters(scaleX: 1.0, scaleY: 1.0, rotation: .zero, offset: .zero)  // Settle
            ]
        }
    }
}

// MARK: - ViewModifier for Squash & Stretch

struct SquashStretchModifier: ViewModifier {
    let parameters: SquashStretchAnimation.Parameters
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(x: parameters.scaleX, y: parameters.scaleY)
            .rotationEffect(parameters.rotation)
            .offset(parameters.offset)
    }
}

extension View {
    func squashStretch(_ params: SquashStretchAnimation.Parameters) -> some View {
        self.modifier(SquashStretchModifier(parameters: params))
    }
}

// MARK: - Circular Bracket Morph (Enhanced)

struct CircularBracketMorph: Shape {
    var morphProgress: Double  // 0.0 = brackets, 1.0 = circle
    var pulseAmount: Double = 0.0  // Breathing effect
    
    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(morphProgress, pulseAmount) }
        set {
            morphProgress = newValue.first
            pulseAmount = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let baseRadius = min(rect.width, rect.height) / 2 - 10
        let radius = baseRadius * (1.0 + pulseAmount * 0.1)
        
        if morphProgress < 0.5 {
            // Bracket mode with smooth corners
            drawBrackets(in: rect, path: &path, progress: morphProgress * 2)
        } else {
            // Circle mode with pulse
            let circleProgress = (morphProgress - 0.5) * 2
            
            // Interpolate from bracket points to circle
            if circleProgress < 1.0 {
                drawTransitionShape(in: rect, path: &path, progress: circleProgress, radius: radius, center: center)
            } else {
                // Full circle
                path.addEllipse(in: CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width: radius * 2,
                    height: radius * 2
                ))
            }
        }
        
        return path
    }
    
    private func drawBrackets(in rect: CGRect, path: inout Path, progress: Double) {
        let length = min(rect.width, rect.height) * 0.25
        let thickness: CGFloat = 2
        let cornerRadius: CGFloat = 4
        
        // Top-left
        path.move(to: CGPoint(x: thickness, y: length))
        path.addLine(to: CGPoint(x: thickness, y: cornerRadius))
        path.addQuadCurve(
            to: CGPoint(x: cornerRadius, y: thickness),
            control: CGPoint(x: thickness, y: thickness)
        )
        path.addLine(to: CGPoint(x: length, y: thickness))
        
        // Top-right
        path.move(to: CGPoint(x: rect.width - length, y: thickness))
        path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: thickness))
        path.addQuadCurve(
            to: CGPoint(x: rect.width - thickness, y: cornerRadius),
            control: CGPoint(x: rect.width - thickness, y: thickness)
        )
        path.addLine(to: CGPoint(x: rect.width - thickness, y: length))
        
        // Bottom-right
        path.move(to: CGPoint(x: rect.width - thickness, y: rect.height - length))
        path.addLine(to: CGPoint(x: rect.width - thickness, y: rect.height - cornerRadius))
        path.addQuadCurve(
            to: CGPoint(x: rect.width - cornerRadius, y: rect.height - thickness),
            control: CGPoint(x: rect.width - thickness, y: rect.height - thickness)
        )
        path.addLine(to: CGPoint(x: rect.width - length, y: rect.height - thickness))
        
        // Bottom-left
        path.move(to: CGPoint(x: length, y: rect.height - thickness))
        path.addLine(to: CGPoint(x: cornerRadius, y: rect.height - thickness))
        path.addQuadCurve(
            to: CGPoint(x: thickness, y: rect.height - cornerRadius),
            control: CGPoint(x: thickness, y: rect.height - thickness)
        )
        path.addLine(to: CGPoint(x: thickness, y: rect.height - length))
    }
    
    private func drawTransitionShape(in rect: CGRect, path: inout Path, progress: Double, radius: CGFloat, center: CGPoint) {
        // Smooth transition from brackets to circle
        let angles: [Double] = [225, 315, 45, 135]  // Corner angles
        
        for (index, angle) in angles.enumerated() {
            let startAngle = Angle(degrees: angle - 45 * (1 - progress))
            let endAngle = Angle(degrees: angle + 45 * (1 - progress))
            
            path.addArc(
                center: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
        }
    }
}
