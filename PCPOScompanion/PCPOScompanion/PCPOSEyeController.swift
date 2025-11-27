import SwiftUI
import Combine

// MARK: - Eye Animation Controller

struct PCPOSEye: Shape {
    let geometry: PCPOSFaceProfile.EyeGeometry
    let isLeft: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Apply squash & stretch based on openness
        let effectiveHeight = geometry.height * geometry.openness
        let anticipation = geometry.squint * 0.2 // Slight compression
        
        // Calculate positions
        let center = CGPoint(
            x: rect.midX + geometry.center.x + geometry.gazeOffset.x * 5,
            y: rect.midY + geometry.center.y + geometry.gazeOffset.y * 3
        )
        
        // Bracket curvature (Disney follow-through)
        let curvature = geometry.width * 0.3 * geometry.openness
        
        // Draw bracket shape
        let leftX = center.x - geometry.width/2
        let topY = center.y - effectiveHeight/2 * (1 - anticipation)
        let bottomY = center.y + effectiveHeight/2 * (1 - anticipation)
        
        path.move(to: CGPoint(x: leftX, y: topY))
        path.addQuadCurve(
            to: CGPoint(x: leftX, y: bottomY),
            control: CGPoint(x: leftX - curvature, y: center.y)
        )
        
        return path
    }
}

// MARK: - Eye Controller

@MainActor
class PCPOSEyeController: ObservableObject {
    @Published private(set) var leftEye: PCPOSFaceProfile.EyeGeometry
    @Published private(set) var rightEye: PCPOSFaceProfile.EyeGeometry
    
    private var blinkTimer: Timer?
    private var saccadeTimer: Timer?
    
    init(leftEye: PCPOSFaceProfile.EyeGeometry, rightEye: PCPOSFaceProfile.EyeGeometry) {
        self.leftEye = leftEye
        self.rightEye = rightEye
    }
    
    // MARK: - Blink Animation (Disney Principles)
    
    func blink(duration: Double = 0.15) {
        // Asymmetric timing: left eye 20ms before right
        withAnimation(.easeInOut(duration: duration * 0.4)) {
            leftEye.openness = 0.0
        }
        
        withAnimation(.easeInOut(duration: duration * 0.4).delay(0.02)) {
            rightEye.openness = 0.0
        }
        
        // Reopen with slight overshoot (follow-through)
        withAnimation(.spring(response: duration * 0.8, dampingFraction: 0.7).delay(duration * 0.5)) {
            leftEye.openness = 1.05
            rightEye.openness = 1.05
        }
        
        // Settle back to normal
        withAnimation(.easeOut(duration: duration * 0.3).delay(duration * 1.3)) {
            leftEye.openness = 1.0
            rightEye.openness = 1.0
        }
    }
    
    // Auto-blink with natural variation
    func startAutoBlink(interval: TimeInterval = 4.0) {
        blinkTimer?.invalidate()
        blinkTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            // Random variation ±1 second
            let randomDelay = Double.random(in: -1.0...1.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + randomDelay) {
                self?.blink()
            }
        }
    }
    
    func stopAutoBlink() {
        blinkTimer?.invalidate()
        blinkTimer = nil
    }
    
    // MARK: - Gaze Control
    
    func updateGaze(x: CGFloat, y: CGFloat, animated: Bool = true) {
        let targetGaze = CGPoint(
            x: max(-1, min(1, x)),
            y: max(-1, min(1, y))
        )
        
        if animated {
            // Saccade: quick jerky movement
            withAnimation(.easeOut(duration: 0.08)) {
                leftEye.gazeOffset = targetGaze
                rightEye.gazeOffset = targetGaze
            }
        } else {
            leftEye.gazeOffset = targetGaze
            rightEye.gazeOffset = targetGaze
        }
    }
    
    // Smooth pursuit: follow moving target
    func trackTarget(_ target: CGPoint, in bounds: CGSize) {
        let normalizedX = (target.x - bounds.width/2) / (bounds.width/2)
        let normalizedY = (target.y - bounds.height/2) / (bounds.height/2)
        
        withAnimation(.linear(duration: 0.3)) {
            updateGaze(x: normalizedX, y: normalizedY, animated: false)
        }
    }
    
    // MARK: - Squint Control
    
    func setSquint(_ amount: CGFloat, animated: Bool = true) {
        let squintAmount = max(0, min(1, amount))
        
        if animated {
            withAnimation(.easeInOut(duration: 0.2)) {
                leftEye.squint = squintAmount
                rightEye.squint = squintAmount
                
                // Squinting reduces openness slightly
                let opennessReduction = squintAmount * 0.3
                leftEye.openness = 1.0 - opennessReduction
                rightEye.openness = 1.0 - opennessReduction
            }
        } else {
            leftEye.squint = squintAmount
            rightEye.squint = squintAmount
        }
    }
    
    // MARK: - Saccades (Random Eye Movements)
    
    func startNaturalSaccades(interval: TimeInterval = 2.5) {
        saccadeTimer?.invalidate()
        saccadeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            let randomX = CGFloat.random(in: -0.3...0.3)
            let randomY = CGFloat.random(in: -0.2...0.2)
            self?.updateGaze(x: randomX, y: randomY, animated: true)
        }
    }
    
    func stopNaturalSaccades() {
        saccadeTimer?.invalidate()
        saccadeTimer = nil
    }
    
    // MARK: - Expression Correlation
    
    func correlateWithSmile(_ smileAmount: CGFloat) {
        // Eyes squint 30% when smiling heavily
        if smileAmount > 0.6 {
            setSquint((smileAmount - 0.6) * 0.75, animated: true)
        } else {
            setSquint(0, animated: true)
        }
    }
    
    deinit {
        blinkTimer?.invalidate()
        saccadeTimer?.invalidate()
    }
}

// MARK: - SwiftUI View

struct PCPOSEyeView: View {
    let geometry: PCPOSFaceProfile.EyeGeometry
    let isLeft: Bool
    let color: Color
    
    var body: some View {
        PCPOSEye(geometry: geometry, isLeft: isLeft)
            .stroke(color, style: StrokeStyle(
                lineWidth: geometry.thickness,
                lineCap: .round,
                lineJoin: .round
            ))
    }
}
