import SwiftUI
import AVFoundation
import Combine

// MARK: - Viseme Definitions

enum Viseme: String, Codable, CaseIterable {
    case neutral
    case AA  // "father" - open wide
    case AE  // "cat" - mid-open
    case AH  // "cut" - slightly open
    case EE  // "see" - narrow smile
    case OO  // "boot" - rounded
    case OH  // "go" - medium round
    case FV  // "five" - lip contact
    case MBP // "map" - closed lips
    case TH  // "think" - tongue visible
    
    var parameters: VisemeParams {
        switch self {
        case .neutral: return VisemeParams(width: 1.0, height: 0.0, roundness: 0.0)
        case .AA:      return VisemeParams(width: 1.3, height: 0.8, roundness: 0.0)
        case .AE:      return VisemeParams(width: 1.2, height: 0.4, roundness: 0.0)
        case .AH:      return VisemeParams(width: 1.1, height: 0.3, roundness: 0.0)
        case .EE:      return VisemeParams(width: 0.7, height: 0.2, roundness: 0.0)
        case .OO:      return VisemeParams(width: 0.8, height: 0.5, roundness: 0.8)
        case .OH:      return VisemeParams(width: 1.0, height: 0.6, roundness: 0.5)
        case .FV:      return VisemeParams(width: 1.0, height: 0.2, roundness: 0.0)
        case .MBP:     return VisemeParams(width: 0.8, height: 0.0, roundness: 0.0)
        case .TH:      return VisemeParams(width: 0.9, height: 0.3, roundness: 0.0)
        }
    }
}

struct VisemeParams: Codable {
    let width: CGFloat   // 0.7 = narrow, 1.3 = wide
    let height: CGFloat  // 0.0 = closed, 1.0 = fully open
    let roundness: CGFloat // 0.0 = spread, 1.0 = round (O shape)
}

// MARK: - Mouth Shape

struct PCPOSMouth: Shape {
    let geometry: PCPOSFaceProfile.MouthGeometry
    let smile: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Current viseme modulates width and height
        let effectiveWidth = geometry.width * geometry.mouthWidth
        let effectiveHeight = geometry.height * geometry.openness
        
        let center = CGPoint(
            x: rect.midX + geometry.center.x,
            y: rect.midY + geometry.center.y
        )
        
        // Smile affects curvature (Disney principle: arcs)
        let smileCurvature = smile * effectiveWidth * 0.3
        
        let leftX = center.x - effectiveWidth/2
        let rightX = center.x + effectiveWidth/2
        
        // Upper lip arc
        path.move(to: CGPoint(x: leftX, y: center.y))
        path.addQuadCurve(
            to: CGPoint(x: rightX, y: center.y),
            control: CGPoint(x: center.x, y: center.y - smileCurvature)
        )
        
        // If mouth open, add lower lip
        if geometry.openness > 0.1 {
            // Lower lip with roundness for "O" shapes
            let roundnessFactor = getRoundness()
            let lowerCurveY = center.y + effectiveHeight
            let lowerControlY = center.y + effectiveHeight * (1 - roundnessFactor * 0.3)
            
            path.addQuadCurve(
                to: CGPoint(x: leftX, y: center.y),
                control: CGPoint(x: center.x, y: lowerControlY)
            )
            path.closeSubpath()
        }
        
        return path
    }
    
    private func getRoundness() -> CGFloat {
        // Extract roundness from current viseme
        guard let viseme = Viseme(rawValue: geometry.viseme) else { return 0 }
        return viseme.parameters.roundness
    }
}

// MARK: - Mouth Controller

@MainActor
class PCPOSMouthController: ObservableObject {
    @Published private(set) var mouth: PCPOSFaceProfile.MouthGeometry
    
    private var visemeTimer: Timer?
    
    init(mouth: PCPOSFaceProfile.MouthGeometry) {
        self.mouth = mouth
    }
    
    // MARK: - Smile Animation
    
    func setSmile(_ amount: CGFloat, animated: Bool = true) {
        let targetSmile = max(-1, min(1, amount))
        
        if animated {
            withAnimation(.easeInOut(duration: 0.3)) {
                mouth.smile = targetSmile
            }
        } else {
            mouth.smile = targetSmile
        }
    }
    
    // MARK: - Viseme Control
    
    func setViseme(_ viseme: Viseme, animated: Bool = true) {
        let params = viseme.parameters
        
        if animated {
            // Disney: Anticipation - slight compression before opening
            if params.height > 0.3 {
                withAnimation(.easeOut(duration: 0.05)) {
                    mouth.openness = params.height * 0.5
                }
            }
            
            // Main action with follow-through
            withAnimation(.spring(response: 0.15, dampingFraction: 0.7).delay(0.05)) {
                mouth.mouthWidth = params.width
                mouth.openness = params.height
                mouth.viseme = viseme.rawValue
            }
        } else {
            mouth.mouthWidth = params.width
            mouth.openness = params.height
            mouth.viseme = viseme.rawValue
        }
    }
    
    // MARK: - Speech Animation
    
    func speak(_ text: String, duration: Double) {
        let visemes = textToVisemes(text)
        let timePerViseme = duration / Double(visemes.count)
        
        var delay: TimeInterval = 0
        for viseme in visemes {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.setViseme(viseme, animated: true)
            }
            delay += timePerViseme
        }
        
        // Return to neutral after speech
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.setViseme(.neutral, animated: true)
        }
    }
    
    // MARK: - Viseme Detection (Simplified)
    
    private func textToVisemes(_ text: String) -> [Viseme] {
        var visemes: [Viseme] = []
        let words = text.lowercased().split(separator: " ")
        
        for word in words {
            for char in word {
                switch char {
                case "a": visemes.append(.AA)
                case "e": visemes.append(.EE)
                case "i": visemes.append(.EE)
                case "o": visemes.append(.OH)
                case "u": visemes.append(.OO)
                case "m", "b", "p": visemes.append(.MBP)
                case "f", "v": visemes.append(.FV)
                default: visemes.append(.AH)
                }
            }
            visemes.append(.neutral) // Pause between words
        }
        
        return visemes
    }
    
    // MARK: - Idle Animation (Subtle Breathing)
    
    func startIdleBreathing() {
        visemeTimer?.invalidate()
        visemeTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            // Subtle mouth movement (breathing)
            withAnimation(.easeInOut(duration: 1.5)) {
                self?.mouth.openness = 0.05
            }
            withAnimation(.easeInOut(duration: 1.5).delay(1.5)) {
                self?.mouth.openness = 0.0
            }
        }
    }
    
    func stopIdleBreathing() {
        visemeTimer?.invalidate()
        visemeTimer = nil
    }
    
    deinit {
        visemeTimer?.invalidate()
    }
}

// MARK: - SwiftUI View

struct PCPOSMouthView: View {
    let geometry: PCPOSFaceProfile.MouthGeometry
    let smile: CGFloat
    let color: Color
    
    var body: some View {
        PCPOSMouth(geometry: geometry, smile: smile)
            .stroke(color, style: StrokeStyle(
                lineWidth: geometry.thickness,
                lineCap: .round,
                lineJoin: .round
            ))
    }
}
