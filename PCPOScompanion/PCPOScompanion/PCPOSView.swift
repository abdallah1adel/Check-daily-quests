import SwiftUI

struct PCPOSView: View {
    var params: AnimationParams
    
    var body: some View {
        ZStack {
            // 1. Helmet / Head Shape
            Circle()
                .fill(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    Circle().stroke(Color.cyan, lineWidth: 4)
                )
                .shadow(color: Color.blue.opacity(0.5), radius: 10)
            
            // Ear Pieces
            HStack {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                Spacer()
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }
            .padding(.horizontal, -10)
            
            // 2. Face Area
            Circle()
                .fill(Color(red: 1.0, green: 0.9, blue: 0.8)) // Skin tone
                .scaleEffect(0.75)
                .offset(y: 10)
            
            // 3. PCPOS Face Features (from face22.svg)
            ZStack {
                    // Left Eye (Disney-enhanced with personality)
                    PCPOSLeftEye(
                        blink: params.eyeOpen,
                        squint: params.browRaise > 0.3 ? 0.6 : 0.0, // Disney: Anticipation through squint
                        excitement: abs(params.mouthSmile) > 0.5 ? 0.4 : 0.0 // Disney: Exaggeration for emotion
                    )
                    .fill(Color.green.opacity(0.95))
                    .frame(width: 150, height: 150)
                    .offset(y: -10)

                    // Right Eye (Disney secondary action - follows left with delay)
                    PCPOSRightEye(
                        blink: params.eyeOpen,
                        squint: params.browRaise > 0.3 ? 0.5 : 0.0, // Slightly delayed squint
                        excitement: abs(params.mouthSmile) > 0.5 ? 0.35 : 0.0 // Slightly less exaggerated
                    )
                    .fill(Color.green.opacity(0.95))
                    .frame(width: 150, height: 150)
                    .offset(y: -10)

                    // Mouth (Disney appeal - most expressive feature)
                    PCPOSDisneyMouth(
                        smile: max(0, min(1, (params.mouthSmile + 1) / 2)), // Map to 0-1 range
                        open: params.mouthOpen,
                        exaggeration: abs(params.mouthSmile) > 0.7 ? 0.6 : 0.2 // Disney exaggeration
                    )
                    .fill(Color.green.opacity(0.95))
                    .frame(width: 150, height: 150)
                    .offset(y: 15)
            }
            
            // 5. Helmet Emblem (Forehead)
            Circle()
                .fill(Color.red)
                .frame(width: 30, height: 30)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .offset(y: -80)
                .shadow(color: Color.red.opacity(0.8), radius: 5)
        }
        .scaleEffect(1.0 + params.glow * 0.05) // Subtle pulse with glow
    }
}

struct EyeView: View {
    var isOpen: CGFloat
    var browRaise: CGFloat
    var color: Color
    
    var body: some View {
        ZStack {
            // White of eye
            Capsule()
                .fill(Color.white)
                .frame(width: 35, height: 45 * isOpen)
            
            // Iris
            Circle()
                .fill(color)
                .frame(width: 20, height: 20)
            
            // Pupil
            Circle()
                .fill(Color.black)
                .frame(width: 10, height: 10)
            
            // Brow
            Capsule()
                .fill(Color.blue) // Helmet color brow
                .frame(width: 40, height: 6)
                .offset(y: -25 - (browRaise * 10))
                .rotationEffect(.degrees(browRaise * -10)) // Anger/Surprise tilt
        }
    }
}

struct MouthView: Shape {
    var smile: CGFloat // -1 to 1
    var open: CGFloat // 0 to 1
    
    nonisolated var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(smile, open) }
        set {
            smile = newValue.first
            open = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Simple quadratic curve for smile
        // Control point Y moves up/down based on smile
        let start = CGPoint(x: 0, y: height/2)
        let end = CGPoint(x: width, y: height/2)
        
        // Smile factor: Positive = Smile (control point down), Negative = Frown (control point up)
        let controlY = height/2 + (smile * 15)
        
        // Open factor: Separates the lips
        let upperLipOffset = open * -10
        let lowerLipOffset = open * 10
        
        // Upper Lip
        path.move(to: CGPoint(x: start.x, y: start.y + upperLipOffset))
        path.addQuadCurve(to: CGPoint(x: end.x, y: end.y + upperLipOffset), control: CGPoint(x: width/2, y: controlY + upperLipOffset))
        
        // Lower Lip (if open)
        if open > 0.1 {
            path.move(to: CGPoint(x: start.x, y: start.y + lowerLipOffset))
            path.addQuadCurve(to: CGPoint(x: end.x, y: end.y + lowerLipOffset), control: CGPoint(x: width/2, y: controlY + lowerLipOffset))
            
            // Connect sides for open mouth
            path.addLine(to: CGPoint(x: end.x, y: end.y + upperLipOffset))
            path.addLine(to: CGPoint(x: start.x, y: start.y + upperLipOffset))
            path.closeSubpath()
        }
        
        return path
    }
}
