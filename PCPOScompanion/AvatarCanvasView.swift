import SwiftUI

struct AvatarCanvasView: View {
    var params: AnimationParams
    
    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                let center = CGPoint(x: size.width/2, y: size.height/2)
                let headRadius = min(size.width, size.height) * 0.45
                
                // NEON STYLE UPDATE
                // Dark background handled by parent view usually, but we can draw a dark circle
                let faceRect = CGRect(x: center.x - headRadius, y: center.y - headRadius, width: headRadius*2, height: headRadius*2)
                ctx.fill(Path(ellipseIn: faceRect), with: .color(.black))
                
                // Neon Stroke
                ctx.stroke(Path(ellipseIn: faceRect), with: .color(params.colorTint), lineWidth: 4)
                
                // Glow effect
                if params.glow > 0 {
                    let glowRadius = headRadius * (1.0 + params.glow * 0.1)
                    let glowRect = CGRect(x: center.x - glowRadius, y: center.y - glowRadius, width: glowRadius*2, height: glowRadius*2)
                    ctx.stroke(Path(ellipseIn: glowRect), with: .color(params.colorTint.opacity(0.5)), lineWidth: 2)
                }
                
                // Eyes (Capsules)
                let eyeOffsetX = headRadius * 0.35
                let eyeY = center.y - headRadius * 0.1
                let eyeWidth = headRadius * 0.25
                let eyeHeight = headRadius * 0.3 * (0.2 + params.eyeOpen * 0.8)
                
                let leftEyeRect = CGRect(x: center.x - eyeOffsetX - eyeWidth/2, y: eyeY - eyeHeight/2, width: eyeWidth, height: eyeHeight)
                let rightEyeRect = CGRect(x: center.x + eyeOffsetX - eyeWidth/2, y: eyeY - eyeHeight/2, width: eyeWidth, height: eyeHeight)
                
                // Neon Eyes (Filled + Glow)
                ctx.fill(Path(ellipseIn: leftEyeRect), with: .color(params.colorTint))
                ctx.fill(Path(ellipseIn: rightEyeRect), with: .color(params.colorTint))
                
                // Brows (Thick Lines)
                let browWidth = eyeWidth * 1.2
                let browYBase = eyeY - eyeHeight/2 - headRadius * 0.15
                let browLift = params.browRaise * headRadius * 0.1
                
                let leftBrowPath = Path { p in
                    p.move(to: CGPoint(x: leftEyeRect.midX - browWidth/2, y: browYBase - browLift))
                    p.addLine(to: CGPoint(x: leftEyeRect.midX + browWidth/2, y: browYBase - browLift))
                }
                let rightBrowPath = Path { p in
                    p.move(to: CGPoint(x: rightEyeRect.midX - browWidth/2, y: browYBase - browLift))
                    p.addLine(to: CGPoint(x: rightEyeRect.midX + browWidth/2, y: browYBase - browLift))
                }
                
                ctx.stroke(leftBrowPath, with: .color(params.colorTint), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                ctx.stroke(rightBrowPath, with: .color(params.colorTint), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                
                // Mouth (Neon Arc)
                let mouthWidth = headRadius * 0.5
                let mouthY = center.y + headRadius * 0.35 + (params.mouthOpen * 10)
                
                var mouthPath = Path()
                let mouthStart = CGPoint(x: center.x - mouthWidth/2, y: mouthY)
                let mouthEnd = CGPoint(x: center.x + mouthWidth/2, y: mouthY)
                
                mouthPath.move(to: mouthStart)
                
                let smileOffset = params.mouthSmile * headRadius * 0.2
                let cp1 = CGPoint(x: mouthStart.x + mouthWidth/3, y: mouthY + smileOffset + (params.mouthOpen * 20))
                let cp2 = CGPoint(x: mouthEnd.x - mouthWidth/3, y: mouthY + smileOffset + (params.mouthOpen * 20))
                
                mouthPath.addCurve(to: mouthEnd, control1: cp1, control2: cp2)
                
                if params.mouthOpen > 0.1 {
                     let openHeight = params.mouthOpen * headRadius * 0.3
                     let cp3 = CGPoint(x: mouthEnd.x - mouthWidth/3, y: mouthY - openHeight)
                     let cp4 = CGPoint(x: mouthStart.x + mouthWidth/3, y: mouthY - openHeight)
                     mouthPath.addCurve(to: mouthStart, control1: cp3, control2: cp4)
                     ctx.fill(mouthPath, with: .color(params.colorTint))
                } else {
                    ctx.stroke(mouthPath, with: .color(params.colorTint), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                }
                
            }
            .rotationEffect(Angle(radians: params.headTilt))
        }
    }
}
