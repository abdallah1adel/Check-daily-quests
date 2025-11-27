import SwiftUI
import QuartzCore

// MARK: - High Performance Loop (120fps)
// Uses CADisplayLink for ultra-low latency (8.33ms) updates

class HighPerformanceLoop: ObservableObject {
    
    // MARK: - State
    @Published var deltaTime: Double = 0.0
    @Published var fps: Double = 0.0
    @Published var frameCount: Int = 0
    
    // MARK: - Display Link
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    
    // MARK: - Update Handlers
    typealias UpdateBlock = (Double) -> Void
    private var updateBlocks: [String: UpdateBlock] = [:]
    
    // MARK: - Initialization
    init() {
        setupDisplayLink()
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Setup
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(step))
        
        // Enable high frame rate (ProMotion 120Hz)
        if #available(iOS 15.0, *) {
            displayLink?.preferredFrameRateRange = CAFrameRateRange(
                minimum: 60,
                maximum: 120,
                preferred: 120
            )
        } else {
            displayLink?.preferredFramesPerSecond = 60 // Fallback
        }
        
        displayLink?.add(to: .main, forMode: .common)
        displayLink?.isPaused = true
    }
    
    // MARK: - Control
    func start() {
        lastTimestamp = CACurrentMediaTime()
        displayLink?.isPaused = false
    }
    
    func stop() {
        displayLink?.isPaused = true
    }
    
    // MARK: - Loop Step
    @objc private func step(displayLink: CADisplayLink) {
        let currentTimestamp = displayLink.timestamp
        
        // Calculate delta time (seconds)
        // Guard against huge jumps (e.g. after pause)
        let rawDelta = displayLink.targetTimestamp - displayLink.timestamp
        let dt = min(rawDelta, 0.1) // Cap at 100ms
        
        self.deltaTime = dt
        self.frameCount += 1
        
        // Calculate FPS (moving average)
        let currentFPS = 1.0 / (displayLink.targetTimestamp - displayLink.timestamp)
        self.fps = self.fps * 0.9 + currentFPS * 0.1
        
        // Run updates
        for block in updateBlocks.values {
            block(dt)
        }
    }
    
    // MARK: - Registration
    func register(id: String, block: @escaping UpdateBlock) {
        updateBlocks[id] = block
    }
    
    func unregister(id: String) {
        updateBlocks.removeValue(forKey: id)
    }
}

// MARK: - Physics Engine Integration

class PhysicsEngine {
    private var particles: [PhysicsParticle] = []
    
    struct PhysicsParticle {
        var position: CGPoint
        var velocity: CGVector
        var acceleration: CGVector
        var mass: Double
        var damping: Double
    }
    
    func update(dt: Double) {
        for i in 0..<particles.count {
            // Symplectic Euler integration
            particles[i].velocity.dx += particles[i].acceleration.dx * dt
            particles[i].velocity.dy += particles[i].acceleration.dy * dt
            
            // Damping
            particles[i].velocity.dx *= (1.0 - particles[i].damping)
            particles[i].velocity.dy *= (1.0 - particles[i].damping)
            
            particles[i].position.x += particles[i].velocity.dx * dt
            particles[i].position.y += particles[i].velocity.dy * dt
        }
    }
}
