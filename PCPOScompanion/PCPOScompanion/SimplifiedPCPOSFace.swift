import SwiftUI

/// Simplified PCPOS Face (Apple Style)
/// Based on user images - Simple, clean, expressive
struct SimplifiedPCPOSFace: View {
    @ObservedObject var faceModel: PCPOSFaceModel
    @ObservedObject var speechManager: SpeechManager
    
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            
            ZStack {
                // Circle Container (Like Apple Widget)
                Circle()
                    .fill(Color.black)
                    .overlay(
                        Circle()
                            .stroke(Color(hex: faceModel.profile.appearance.colors.primary), lineWidth: 3)
                    )
                
                // Face Features
                VStack(spacing: size * 0.08) {
                    // Eyes Row
                    HStack(spacing: size * 0.15) {
                        // Left Eye (Parabolic Top Cut)
                        ParabolicEye(
                            eyebrowCut: faceModel.profile.geometry.eyeLeft.squint,
                            blinkAmount: faceModel.profile.geometry.eyeLeft.openness
                        )
                        .fill(Color(hex: faceModel.profile.appearance.colors.primary))
                        .frame(width: size * 0.12, height: size * 0.12)
                        
                        // Right Eye
                        ParabolicEye(
                            eyebrowCut: faceModel.profile.geometry.eyeLeft.squint,
                            blinkAmount: faceModel.profile.geometry.eyeLeft.openness
                        )
                        .fill(Color(hex: faceModel.profile.appearance.colors.primary))
                        .frame(width: size * 0.12, height: size * 0.12)
                    }
                    .offset(y: -size * 0.05)
                    
                    // Nose
                    Ellipse()
                        .fill(Color(hex: faceModel.profile.appearance.colors.primary))
                        .frame(width: size * 0.05, height: size * 0.08)
                        .offset(y: -size * 0.08)
                    
                    // Mouth with Lip Sync
                    ExpandableMouth(
                        openAmount: CGFloat(speechManager.audioLevel),
                        smileAmount: faceModel.profile.geometry.mouth.smile
                    )
                    .stroke(Color(hex: faceModel.profile.appearance.colors.primary), lineWidth: 3)
                    .frame(width: size * 0.25, height: size * 0.15)
                    .offset(y: -size * 0.05)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// Parabolic Eye Shape (Circle with parabolic top cut for eyebrow effect)
struct ParabolicEye: Shape {
    let eyebrowCut: CGFloat // 0.0 = no cut, 1.0 = full eyebrow raise
    let blinkAmount: CGFloat // 0.0 = open, 1.0 = closed
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        // Calculate blink effect (scale vertically)
        let verticalScale = 1.0 - blinkAmount
        
        // Create ellipse for blink
        let ellipseRect = CGRect(
            x: center.x - radius,
            y: center.y - radius * verticalScale,
            width: radius * 2,
            height: radius * 2 * verticalScale
        )
        
        if blinkAmount > 0.9 {
            // Fully closed - just a line
            path.move(to: CGPoint(x: rect.minX, y: center.y))
            path.addLine(to: CGPoint(x: rect.maxX, y: center.y))
        } else {
            // Draw circle/ellipse
            path.addEllipse(in: ellipseRect)
            
            // Cut top with parabola for eyebrow effect
            if eyebrowCut > 0.01 {
                let cutHeight = radius * eyebrowCut * 0.4
                
                var parabolaPath = Path()
                parabolaPath.move(to: CGPoint(x: center.x - radius, y: center.y - radius * verticalScale))
                
                // Parabolic curve
                let controlPoint = CGPoint(x: center.x, y: center.y - radius * verticalScale - cutHeight)
                parabolaPath.addQuadCurve(
                    to: CGPoint(x: center.x + radius, y: center.y - radius * verticalScale),
                    control: controlPoint
                )
                parabolaPath.addLine(to: CGPoint(x: center.x + radius, y: center.y - radius * verticalScale - cutHeight * 2))
                parabolaPath.addQuadCurve(
                    to: CGPoint(x: center.x - radius, y: center.y - radius * verticalScale - cutHeight * 2),
                    control: CGPoint(x: center.x, y: center.y - radius * verticalScale - cutHeight * 3)
                )
                parabolaPath.closeSubpath()
                
                // Subtract the parabola from the circle
                path = path.subtracting(parabolaPath)
            }
        }
        
        return path
    }
}

/// Expandable Mouth with Lip Sync
struct ExpandableMouth: Shape {
    let openAmount: CGFloat // 0.0 = closed, 1.0 = fully open (from audio)
    let smileAmount: CGFloat // -1.0 = frown, 0.0 = neutral, 1.0 = smile
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let width = rect.width
        let baseHeight = rect.height * 0.3
        
        // Calculate mouth shape based on smile and open amount
        let smileCurvature = smileAmount * baseHeight
        let openHeight = openAmount * rect.height
        
        // Start point (left)
        path.move(to: CGPoint(x: center.x - width/2, y: center.y))
        
        if openAmount > 0.1 {
            // Open mouth (O shape)
            let verticalRadius = baseHeight + openHeight
            let mouthRect = CGRect(
                x: center.x - width/2,
                y: center.y - verticalRadius/2,
                width: width,
                height: verticalRadius
            )
            path.addEllipse(in: mouthRect)
        } else {
            // Closed mouth (smile/frown line)
            // Upper curve (smile/frown)
            path.addQuadCurve(
                to: CGPoint(x: center.x + width/2, y: center.y),
                control: CGPoint(x: center.x, y: center.y + smileCurvature)
            )
        }
        
        return path
    }
}

#if DEBUG
struct SimplifiedPCPOSFace_Previews: PreviewProvider {
    static var previews: some View {
        SimplifiedPCPOSFace(
            faceModel: PCPOSFaceModel(),
            speechManager: SpeechManager()
        )
        .frame(width: 200, height: 200)
        .background(Color.gray)
    }
}
#endif
