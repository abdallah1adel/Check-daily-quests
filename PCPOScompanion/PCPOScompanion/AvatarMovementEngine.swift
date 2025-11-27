import Foundation
import SwiftUI
import Combine

@MainActor
class AvatarMovementEngine: ObservableObject {
    @Published var offsetX: CGFloat = 0
    @Published var offsetY: CGFloat = 0
    @Published var scaleMultiplier: CGFloat = 1.0
    @Published var deformationX: CGFloat = 1.0 // Squash/Stretch X
    @Published var deformationY: CGFloat = 1.0 // Squash/Stretch Y
    
    private var lastOffsetX: CGFloat = 0
    private var lastOffsetY: CGFloat = 0
    
    private var timer: Timer?
    private var currentPattern: MovementPattern = .idle
    private var lastScale: CGFloat = 1.0
    
    // Movement boundaries (to keep avatar on screen)
    private let maxOffsetX: CGFloat = 60
    private let maxOffsetY: CGFloat = 40
    
    init() {
        startMovementLoop()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func updateMovement(mood: CompanionMood, arousal: CGFloat, personality: Personality? = nil) {
        let previousPattern = currentPattern
        
        // Determine pattern based on mood + arousal + personality
        if arousal > 0.7 {
            currentPattern = .energetic
        } else if let personality = personality, personality.curiosity > 0.6 {
            currentPattern = .curious
        } else if mood.energy < 0.3 {
            currentPattern = .calm
        } else {
            currentPattern = .idle
        }
        
        // Play haptic on pattern change
        if previousPattern != currentPattern {
            switch currentPattern {
            case .energetic:
                PCPOSHaptics.shared.playEnergetic()
            case .curious:
                PCPOSHaptics.shared.playCurious()
            case .calm:
                PCPOSHaptics.shared.playCalm()
            case .idle:
                break
            }
        }
    }
    
    func triggerShake() {
        // Temporarily add shake offset
        let shakeAmount: CGFloat = 15
        
        withAnimation(.spring(response: 0.15, dampingFraction: 0.3)) {
            offsetX += shakeAmount
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.3)) {
                self.offsetX -= shakeAmount * 2
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.3)) {
                self.offsetX += shakeAmount
            }
        }
    }
    
    private func startMovementLoop() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updatePosition()
        }
    }
    
    private func updatePosition() {
        let time = Date().timeIntervalSince1970
        let previousScale = lastScale
        
        // 1. Calculate Target Position based on Pattern
        var targetX: CGFloat = 0
        var targetY: CGFloat = 0
        var targetScale: CGFloat = 1.0
        
        switch currentPattern {
        case .idle:
            targetX = sin(time * 0.3) * 20
            targetY = sin(time * 0.6) * 15
            targetScale = 1.0 + sin(time * 0.2) * 0.05
            
        case .curious:
            targetX = sin(time * 0.8) * 30
            targetY = cos(time * 0.5) * 10
            targetScale = 1.15 + sin(time * 0.4) * 0.05
            
        case .energetic:
            targetX = sin(time * 2.0) * maxOffsetX
            targetY = abs(sin(time * 3.0)) * maxOffsetY - 10
            targetScale = 1.0 + abs(sin(time * 2.5)) * 0.2
            
            if abs(offsetY - (-10)) < 2 { PCPOSHaptics.shared.playBounce() }
            
        case .calm:
            targetX = sin(time * 0.15) * 40
            targetY = cos(time * 0.2) * 20
            targetScale = 0.9 + sin(time * 0.1) * 0.03
        }
        
        // 2. Apply Smoothing (Inertia)
        let smoothing: CGFloat = 0.1
        offsetX = offsetX + (targetX - offsetX) * smoothing
        offsetY = offsetY + (targetY - offsetY) * smoothing
        scaleMultiplier = scaleMultiplier + (targetScale - scaleMultiplier) * smoothing
        
        // 3. Calculate Velocity
        let velocityX = offsetX - lastOffsetX
        let velocityY = offsetY - lastOffsetY
        
        // 4. Squash & Stretch (Velocity-based)
        // Stretch in direction of movement, squash perpendicular
        let speed = sqrt(velocityX * velocityX + velocityY * velocityY)
        let stretchFactor: CGFloat = 0.1 // Sensitivity
        
        // Base deformation from movement
        var targetDefX = 1.0 + (abs(velocityX) * stretchFactor) - (abs(velocityY) * stretchFactor)
        var targetDefY = 1.0 + (abs(velocityY) * stretchFactor) - (abs(velocityX) * stretchFactor)
        
        // 5. Bezel Collision (Squash against walls)
        // Dynamic Island is roughly 130pt wide, so +/- 65pt from center
        // But avatar moves within a container. Let's assume bounds are +/- 50pt for visual squash.
        let boundaryX: CGFloat = 50
        let boundaryY: CGFloat = 40
        
        if abs(offsetX) > boundaryX {
            // Hitting side wall -> Squash X, Stretch Y
            let penetration = abs(offsetX) - boundaryX
            targetDefX *= max(0.5, 1.0 - penetration * 0.05) // Squash
            targetDefY *= min(1.5, 1.0 + penetration * 0.05) // Stretch
            
            // Haptic impact
            if abs(velocityX) > 2.0 { PCPOSHaptics.shared.playCollision() }
        }
        
        if abs(offsetY) > boundaryY {
            // Hitting top/bottom -> Squash Y, Stretch X
            let penetration = abs(offsetY) - boundaryY
            targetDefY *= max(0.5, 1.0 - penetration * 0.05)
            targetDefX *= min(1.5, 1.0 + penetration * 0.05)
            
            if abs(velocityY) > 2.0 { PCPOSHaptics.shared.playCollision() }
        }
        
        // 6. Apply Deformation with Spring Physics
        // Use a simple spring equation for "jelly" effect
        let springStiffness: CGFloat = 0.2
        let springDamping: CGFloat = 0.15
        
        deformationX = deformationX + (targetDefX - deformationX) * springStiffness
        deformationY = deformationY + (targetDefY - deformationY) * springStiffness
        
        lastOffsetX = offsetX
        lastOffsetY = offsetY
        lastScale = scaleMultiplier
        
        // Haptics for Zoom
        handleZoomHaptics(currentScale: scaleMultiplier, previousScale: previousScale, time: time)
    }
    
    private func handleZoomHaptics(currentScale: CGFloat, previousScale: CGFloat, time: TimeInterval) {
        let scaleDelta = abs(currentScale - previousScale)
        if scaleDelta > 0.05 {
            if currentScale > previousScale && Int(time * 10) % 5 == 0 {
                PCPOSHaptics.shared.playZoomIn()
            } else if Int(time * 10) % 5 == 0 {
                PCPOSHaptics.shared.playZoomOut()
            }
        }
    }
    
    enum MovementPattern {
        case idle
        case curious
        case energetic
        case calm
    }
}
