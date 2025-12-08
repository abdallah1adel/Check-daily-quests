import Foundation
import SwiftUI
import Combine

// MARK: - Advanced Symbol Animation Engine
// Drives Dynamic Island symbol transitions based on word tracking

@MainActor
class AdvancedSymbolAnimationEngine: ObservableObject {
    static let shared = AdvancedSymbolAnimationEngine()
    
    // Current state
    @Published var activeSymbols: [AnimatedSymbol] = []
    @Published var currentWords: [String] = []
    @Published var dominantEmotion: EmotionNode = .neutral
    
    // Animation configuration
    private let maxSymbols = 12
    private let symbolLifetime: TimeInterval = 3.0
    private var animationTimer: Timer?
    
    init() {
        startAnimationLoop()
    }
    
    // MARK: - Word Tracking
    
    func trackSentence(_ sentence: String) {
        currentWords = sentence.lowercased()
            .components(separatedBy: .punctuationCharacters)
            .joined()
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        
        // Update emotion based on semantic graph
        let animationID = SemanticEmotionGraph.shared.processSemantic(sentence)
        dominantEmotion = SemanticEmotionGraph.shared.currentEmotion
        
        // Generate symbols for this emotion
        generateSymbols(for: dominantEmotion, animationID: animationID)
    }
    
    func trackWord(_ word: String) {
        currentWords.append(word.lowercased())
        if currentWords.count > 10 {
            currentWords.removeFirst()
        }
        
        // Process single word
        _ = SemanticEmotionGraph.shared.processSemantic(word)
        dominantEmotion = SemanticEmotionGraph.shared.currentEmotion
    }
    
    // MARK: - Symbol Generation
    
    private func generateSymbols(for emotion: EmotionNode, animationID: Int) {
        let symbols = SemanticEmotionGraph.shared.symbolsForEmotion(emotion)
        let color = SemanticEmotionGraph.shared.colorForEmotion(emotion)
        
        // Clear old symbols
        activeSymbols.removeAll()
        
        // Create new animated symbols
        for (index, symbolName) in symbols.prefix(maxSymbols).enumerated() {
            let symbol = AnimatedSymbol(
                id: UUID(),
                name: symbolName,
                color: color,
                size: CGFloat.random(in: 16...32),
                position: randomPosition(index: index),
                rotation: Angle.degrees(Double.random(in: -30...30)),
                opacity: Double.random(in: 0.6...1.0),
                scale: CGFloat.random(in: 0.8...1.2),
                animationPhase: Double(index) * 0.2,
                emotion: emotion
            )
            activeSymbols.append(symbol)
        }
        
        // ⚠️ CRITICAL: Sync with PCPOSFaceSystem and Live Activity
        if let primarySymbol = symbols.first {
            Task { @MainActor in
                // 1. Update Face System State (Live Activity)
                // Note: PCPOSFaceSystem is unavailable here (Widget scope), so we pass symbol directly to LiveActivityManager
                // PCPOSFaceSystem.shared.currentSymbol = primarySymbol
                // PCPOSFaceSystem.shared.setEmotion(from: emotion.toEmotionState())
                
                // 2. Update Personality Engine (Main UI)
                PersonalityEngine.shared.updateEmotion(from: emotion.toEmotionState())
                
                // 3. Update Live Activity
                if #available(iOS 16.1, *) {
                    LiveActivityManager.shared.updateActivity(
                        emotion: emotion.rawValue,
                        intensity: 0.8,
                        aiState: AIState.thinking, // Or context dependent
                        message: "Processing...",
                        isLargeExpansion: false,
                        currentSymbol: primarySymbol // ⚠️ Pass symbol directly
                    )
                }
            }
        }
        
        print("🎭 Generated \(activeSymbols.count) symbols for \(emotion)")
    }
    
    private func randomPosition(index: Int) -> CGPoint {
        // Distribute symbols in a circular pattern
        let angle = Double(index) * (360.0 / Double(maxSymbols)) * .pi / 180.0
        let radius = CGFloat.random(in: 30...60)
        return CGPoint(
            x: CGFloat(cos(angle)) * radius,
            y: CGFloat(sin(angle)) * radius
        )
    }
    
    // MARK: - Animation Loop
    
    private func startAnimationLoop() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateSymbols()
            }
        }
    }
    
    private func updateSymbols() {
        for index in activeSymbols.indices {
            // Update animation phase
            activeSymbols[index].animationPhase += 0.02
            
            // Animate position (orbital motion)
            let phase = activeSymbols[index].animationPhase
            let basePos = activeSymbols[index].position
            let wobble = CGPoint(
                x: sin(phase * 2) * 5,
                y: cos(phase * 3) * 3
            )
            activeSymbols[index].currentOffset = CGSize(
                width: basePos.x + wobble.x,
                height: basePos.y + wobble.y
            )
            
            // Animate scale (breathing effect)
            activeSymbols[index].currentScale = activeSymbols[index].scale + CGFloat(sin(phase)) * 0.1
            
            // Animate opacity (pulsing)
            activeSymbols[index].currentOpacity = activeSymbols[index].opacity + sin(phase * 1.5) * 0.2
        }
    }
    
    // MARK: - Transition to New Emotion
    
    func transitionTo(emotion: EmotionNode) {
        // Animate out current symbols
        withAnimation(.easeOut(duration: 0.3)) {
            for index in activeSymbols.indices {
                activeSymbols[index].currentOpacity = 0
                activeSymbols[index].currentScale = 0.5
            }
        }
        
        // After fade out, generate new symbols
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.generateSymbols(for: emotion, animationID: 0)
            
            // Animate in new symbols
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                for index in self?.activeSymbols.indices ?? 0..<0 {
                    self?.activeSymbols[index].currentOpacity = self?.activeSymbols[index].opacity ?? 1.0
                    self?.activeSymbols[index].currentScale = self?.activeSymbols[index].scale ?? 1.0
                }
            }
        }
    }
}

// MARK: - Animated Symbol Model

struct AnimatedSymbol: Identifiable {
    let id: UUID
    let name: String
    let color: Color
    let size: CGFloat
    let position: CGPoint
    let rotation: Angle
    let opacity: Double
    let scale: CGFloat
    var animationPhase: Double
    let emotion: EmotionNode
    
    // Animated properties
    var currentOffset: CGSize = .zero
    var currentScale: CGFloat = 1.0
    var currentOpacity: Double = 1.0
}

// MARK: - Symbol Animation View (For Dynamic Island)

struct SymbolAnimationView: View {
    @ObservedObject var engine = AdvancedSymbolAnimationEngine.shared
    
    var body: some View {
        ZStack {
            ForEach(engine.activeSymbols) { symbol in
                Image(systemName: symbol.name)
                    .font(.system(size: symbol.size))
                    .foregroundColor(symbol.color)
                    .rotationEffect(symbol.rotation)
                    .scaleEffect(symbol.currentScale)
                    .opacity(symbol.currentOpacity)
                    .offset(symbol.currentOffset)
            }
        }
    }
}
