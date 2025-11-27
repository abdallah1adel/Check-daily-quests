import SwiftUI

// MARK: - Custom PCPOS Symbol Effect Library
// Individual control for mouth, eyes, and facial expressions

/// Custom symbol effects for facial animation control
struct PCPOSSymbolEffects {
    
    // MARK: - Mouth Effects (Speaking/Lip-Sync)
    
    /// Mouth speaking animation - synced with audio level
    struct MouthSpeak {
        let audioLevel: Double
        let intensity: Double
        
        var openAmount: CGFloat {
            CGFloat(audioLevel * intensity)
        }
        
        var wiggleAngle: Angle {
            .degrees(audioLevel * 15 * intensity)
        }
        
        var scaleMultiplier: CGFloat {
            1.0 + CGFloat(audioLevel * 0.5 * intensity)
        }
    }
    
    /// Mouth smile/frown animation
    struct MouthExpression {
        let smile: Double // -1.0 (frown) to 1.0 (smile)
        let intensity: Double
        
        var curvature: CGFloat {
            CGFloat(smile * 30 * intensity)
        }
        
        var rotation: Angle {
            .degrees(smile * 5 * intensity)
        }
    }
    
    // MARK: - Eye Effects (Blinking/Looking)
    
    /// Eye blink animation
    struct EyeBlink {
        let isBlinking: Bool
        let blinkAmount: Double // 0.0 (open) to 1.0 (closed)
        let speed: Double
        
        var scaleY: CGFloat {
            isBlinking ? CGFloat(1.0 - blinkAmount) : 1.0
        }
        
        var opacity: Double {
            isBlinking ? max(0.3, 1.0 - blinkAmount * 0.7) : 1.0
        }
        
        var animation: Animation {
            .spring(response: 0.1 * speed, dampingFraction: 0.6)
        }
    }
    
    /// Eye gaze/look direction
    struct EyeGaze {
        let direction: CGSize // x: -1 to 1 (left to right), y: -1 to 1 (up to down)
        let intensity: Double
        
        var offset: CGSize {
            CGSize(
                width: direction.width * 5 * intensity,
                height: direction.height * 3 * intensity
            )
        }
        
        var pupilOffset: CGSize {
            CGSize(
                width: direction.width * 2 * intensity,
                height: direction.height * 2 * intensity
            )
        }
    }
    
    /// Eye talk (expressive eye movement while speaking)
    struct EyeTalk {
        let isSpeaking: Bool
        let emphasis: Double // 0.0 to 1.0
        let audioLevel: Double
        
        var scale: CGFloat {
            isSpeaking ? 1.0 + CGFloat(emphasis * 0.2) : 1.0
        }
        
        var squint: CGFloat {
            CGFloat(audioLevel * emphasis * 0.3)
        }
        
        var eyebrowRaise: CGFloat {
            CGFloat(audioLevel * emphasis * 0.4)
        }
    }
    
    // MARK: - Nose Effects
    
    /// Nose wiggle (breathing, sniffing)
    struct NoseWiggle {
        let isActive: Bool
        let frequency: Double
        let amplitude: Double
        
        var rotation: Angle {
            .degrees(isActive ? amplitude * 5 : 0)
        }
        
        var scale: CGFloat {
            1.0 + CGFloat(isActive ? amplitude * 0.1 : 0)
        }
        
        var animation: Animation {
            isActive ? .linear(duration: 1.0 / frequency).repeatForever(autoreverses: true) : .default
        }
    }
    
    // MARK: - Combined Effects
    
    /// Full face expression combining all parts
    struct FaceExpression {
        let mouth: MouthExpression
        let leftEye: EyeBlink
        let rightEye: EyeBlink
        let gaze: EyeGaze
        let nose: NoseWiggle
        
        static func neutral() -> FaceExpression {
            FaceExpression(
                mouth: MouthExpression(smile: 0, intensity: 0.5),
                leftEye: EyeBlink(isBlinking: false, blinkAmount: 0, speed: 1.0),
                rightEye: EyeBlink(isBlinking: false, blinkAmount: 0, speed: 1.0),
                gaze: EyeGaze(direction: .zero, intensity: 0),
                nose: NoseWiggle(isActive: false, frequency: 1.0, amplitude: 0)
            )
        }
        
        static func happy() -> FaceExpression {
            FaceExpression(
                mouth: MouthExpression(smile: 0.8, intensity: 1.0),
                leftEye: EyeBlink(isBlinking: false, blinkAmount: 0.2, speed: 1.0),
                rightEye: EyeBlink(isBlinking: false, blinkAmount: 0.2, speed: 1.0),
                gaze: EyeGaze(direction: .zero, intensity: 0.5),
                nose: NoseWiggle(isActive: false, frequency: 1.0, amplitude: 0.3)
            )
        }
        
        static func speaking(audioLevel: Double) -> FaceExpression {
            FaceExpression(
                mouth: MouthExpression(smile: 0.3, intensity: 1.0),
                leftEye: EyeBlink(isBlinking: false, blinkAmount: 0, speed: 1.0),
                rightEye: EyeBlink(isBlinking: false, blinkAmount: 0, speed: 1.0),
                gaze: EyeGaze(direction: .zero, intensity: audioLevel),
                nose: NoseWiggle(isActive: true, frequency: 2.0, amplitude: audioLevel)
            )
        }
    }
}

// MARK: - Custom Symbol Effect Modifiers

extension View {
    
    /// Apply mouth speaking effect
    func mouthSpeakEffect(_ effect: PCPOSSymbolEffects.MouthSpeak) -> some View {
        self
            .scaleEffect(x: effect.scaleMultiplier, y: 1.0 + effect.openAmount)
            .rotationEffect(effect.wiggleAngle)
            .animation(.spring(response: 0.08, dampingFraction: 0.4), value: effect.audioLevel)
    }
    
    /// Apply mouth expression effect
    func mouthExpressionEffect(_ effect: PCPOSSymbolEffects.MouthExpression) -> some View {
        self
            .rotationEffect(effect.rotation)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: effect.smile)
    }
    
    /// Apply eye blink effect
    func eyeBlinkEffect(_ effect: PCPOSSymbolEffects.EyeBlink) -> some View {
        self
            .scaleEffect(x: 1.0, y: effect.scaleY)
            .opacity(effect.opacity)
            .animation(effect.animation, value: effect.isBlinking)
    }
    
    /// Apply eye gaze effect
    func eyeGazeEffect(_ effect: PCPOSSymbolEffects.EyeGaze) -> some View {
        self
            .offset(effect.offset)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: effect.direction)
    }
    
    /// Apply eye talk effect (expressive eyes while speaking)
    func eyeTalkEffect(_ effect: PCPOSSymbolEffects.EyeTalk) -> some View {
        self
            .scaleEffect(effect.scale)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: effect.isSpeaking)
    }
    
    /// Apply nose wiggle effect
    func noseWiggleEffect(_ effect: PCPOSSymbolEffects.NoseWiggle) -> some View {
        self
            .rotationEffect(effect.rotation)
            .scaleEffect(effect.scale)
            .animation(effect.animation, value: effect.isActive)
    }
    
    /// Apply full face expression
    func faceExpressionEffect(_ expression: PCPOSSymbolEffects.FaceExpression) -> some View {
        self
            .modifier(FaceExpressionModifier(expression: expression))
    }
}

// MARK: - Face Expression ViewModifier

struct FaceExpressionModifier: ViewModifier {
    let expression: PCPOSSymbolEffects.FaceExpression
    
    func body(content: Content) -> some View {
        content
            .mouthExpressionEffect(expression.mouth)
            .noseWiggleEffect(expression.nose)
    }
}

// MARK: - Layered Symbol Animation System

/// Advanced symbol effect composer for layered animations
struct PCPOSLayeredSymbolEffect {
    
    /// Layer configuration for symbol effects
    struct Layer {
        let symbol: String
        let color: Color
        let size: CGFloat
        let offset: CGSize
        let opacity: Double
        let effects: [EffectType]
        
        enum EffectType {
            case pulse(speed: Double)
            case wiggle(angle: Angle, delay: Double)
            case breathe(speed: Double)
            case variableColor(mode: VariableColorMode)
            case bounce(intensity: Double)
            
            enum VariableColorMode {
                case iterative
                case cumulative
                case reversing
            }
        }
    }
    
    /// Create layered symbol view
    static func layered(layers: [Layer]) -> some View {
        ZStack {
            ForEach(Array(layers.enumerated()), id: \.offset) { index, layer in
                Image(systemName: layer.symbol)
                    .font(.system(size: layer.size))
                    .foregroundStyle(layer.color)
                    .offset(layer.offset)
                    .opacity(layer.opacity)
                    .applyEffects(layer.effects)
            }
        }
    }
}

// MARK: - Effect Application Extension

extension View {
    @ViewBuilder
    func applyEffects(_ effects: [PCPOSLayeredSymbolEffect.Layer.EffectType]) -> some View {
        var view = AnyView(self)
        
        for effect in effects {
            switch effect {
            case .pulse(let speed):
                view = AnyView(view.symbolEffect(.pulse, options: .repeat(.continuous).speed(speed)))
            case .wiggle(let angle, let delay):
                view = AnyView(view.symbolEffect(.wiggle.custom(angle: angle).byLayer, options: .repeat(.periodic(delay: delay))))
            case .breathe(let speed):
                view = AnyView(view.symbolEffect(.breathe, options: .repeat(.continuous).speed(speed)))
            case .variableColor(let mode):
                switch mode {
                case .iterative:
                    view = AnyView(view.symbolEffect(.variableColor.iterative))
                case .cumulative:
                    view = AnyView(view.symbolEffect(.variableColor.cumulative))
                case .reversing:
                    view = AnyView(view.symbolEffect(.variableColor.reversing))
                }
            case .bounce(let intensity):
                view = AnyView(view.symbolEffect(.bounce))
            }
        }
        
        return view
    }
}
