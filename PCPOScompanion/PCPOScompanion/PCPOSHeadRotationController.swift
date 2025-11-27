import SwiftUI
import CoreGraphics
import Combine

// MARK: - Head Rotation Controller

@MainActor
class PCPOSHeadRotationController: ObservableObject {
    @Published private(set) var transform: HeadTransform
    
    private let constraints: RotationConstraints
    
    struct RotationConstraints {
        let pitchRange: ClosedRange<CGFloat> = -30...30  // Nod up/down
        let yawRange: ClosedRange<CGFloat> = -45...45    // Turn left/right
        let rollRange: ClosedRange<CGFloat> = -15...15   // Tilt sideways
    }
    
    init(transform: HeadTransform = HeadTransform()) {
        self.transform = transform
        self.constraints = RotationConstraints()
    }
    
    // MARK: - Rotation Methods
    
    func setRotation(pitch: CGFloat? = nil, yaw: CGFloat? = nil, roll: CGFloat? = nil, animated: Bool = true) {
        let targetPitch = pitch.map { constraints.pitchRange.clamp($0) } ?? transform.rotation.pitch
        let targetYaw = yaw.map { constraints.yawRange.clamp($0) } ?? transform.rotation.yaw
        let targetRoll = roll.map { constraints.rollRange.clamp($0) } ?? transform.rotation.roll
        
        if animated {
            // Disney: Anticipation - slight motion in opposite direction
            let anticipationPitch = targetPitch != 0 ? -targetPitch * 0.15 : 0
            let anticipationYaw = targetYaw != 0 ? -targetYaw * 0.15 : 0
            
            withAnimation(.easeOut(duration: 0.1)) {
                transform.rotation.pitch = anticipationPitch
                transform.rotation.yaw = anticipationYaw
            }
            
            // Main action: smooth arc to target
            withAnimation(.easeInOut(duration: 0.4).delay(0.1)) {
                transform.rotation.pitch = targetPitch
                transform.rotation.yaw = targetYaw
                transform.rotation.roll = targetRoll
            }
        } else {
            transform.rotation.pitch = targetPitch
            transform.rotation.yaw = targetYaw
            transform.rotation.roll = targetRoll
        }
    }
    
    // MARK: - Head Turn Animation (with Disney Principles)
    
    func turnHead(to targetYaw: CGFloat, duration: Double = 0.5) {
        let clampedYaw = constraints.yawRange.clamp(targetYaw)
        
        // Anticipation: Quick opposite turn
        withAnimation(.easeOut(duration: duration * 0.2)) {
            transform.rotation.yaw = -clampedYaw * 0.15
        }
        
        // Main action: Arc-based motion
        withAnimation(.easeInOut(duration: duration * 0.8).delay(duration * 0.2)) {
            transform.rotation.yaw = clampedYaw
            
            // Secondary action: slight roll in turn direction
            transform.rotation.roll = clampedYaw / 45.0 * 5.0 // Max 5° roll
        }
    }
    
    func nodHead(up: Bool = true, duration: Double = 0.4) {
        let targetPitch: CGFloat = up ? -15 : 15
        
        withAnimation(.easeInOut(duration: duration)) {
            transform.rotation.pitch = targetPitch
        }
        
        // Return to neutral
        withAnimation(.easeOut(duration: duration * 0.6).delay(duration)) {
            transform.rotation.pitch = 0
        }
    }
    
    func tiltHead(amount: CGFloat, duration: Double = 0.3) {
        let targetRoll = constraints.rollRange.clamp(amount)
        
        withAnimation(.spring(response: duration, dampingFraction: 0.7)) {
            transform.rotation.roll = targetRoll
        }
    }
    
    // MARK: - Reset
    
    func resetToNeutral(animated: Bool = true) {
        if animated {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                transform.rotation.pitch = 0
                transform.rotation.yaw = 0
                transform.rotation.roll = 0
            }
        } else {
            transform.rotation.pitch = 0
            transform.rotation.yaw = 0
            transform.rotation.roll = 0
        }
    }
    
    // MARK: - Affine Transform Generation
    
    func getAffineTransform(for anchorPoint: CGPoint) -> CGAffineTransform {
        return transform.toAffineTransform(anchorPoint: anchorPoint)
    }
}

// MARK: - Range Extension for Clamping

extension ClosedRange where Bound: Comparable {
    func clamp(_ value: Bound) -> Bound {
        return Swift.min(Swift.max(value, lowerBound), upperBound)
    }
}

// MARK: - Head Transform View Modifier

struct HeadRotationModifier: ViewModifier {
    let transform: HeadTransform
    let anchorPoint: UnitPoint
    
    func body(content: Content) -> some View {
        content
            .transformEffect(transform.toAffineTransform(
                anchorPoint: CGPoint(x: anchorPoint.x, y: anchorPoint.y)
            ))
    }
}

extension View {
    func headRotation(_ transform: HeadTransform, anchor: UnitPoint = .center) -> some View {
        modifier(HeadRotationModifier(transform: transform, anchorPoint: anchor))
    }
}

// MARK: - 3D Perspective Helper

struct PerspectiveTransform {
    static func apply(
        to point: CGPoint,
        yaw: CGFloat,
        pitch: CGFloat,
        focalLength: CGFloat = 500
    ) -> CGPoint {
        // Simple perspective projection
        let yawRad = yaw * .pi / 180
        let pitchRad = pitch * .pi / 180
        
        // Z-depth from yaw (farther back when turned)
        let z = focalLength * (1 - abs(sin(yawRad)) * 0.3)
        
        // Perspective scaling
        let scale = focalLength / z
        
        // Apply rotation
        let rotatedX = point.x * cos(yawRad) - point.y * sin(pitchRad)
        let rotatedY = point.y * cos(pitchRad)
        
        return CGPoint(
            x: rotatedX * scale,
            y: rotatedY * scale
        )
    }
}
