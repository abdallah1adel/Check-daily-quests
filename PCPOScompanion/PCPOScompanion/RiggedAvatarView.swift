import SwiftUI

struct RiggedAvatarView: View {
    var image: UIImage
    var landmarks: RiggingLandmarks
    var params: AnimationParams
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 1. Base Image
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                
                // 2. Animated Overlays
                // We overlay vector eyes/mouth at the normalized coordinates
                
                // Left Eye
                let leftEyePos = CGPoint(x: landmarks.leftEye.x * geo.size.width, y: landmarks.leftEye.y * geo.size.height)
                EyeOverlay(params: params)
                    .frame(width: geo.size.width * 0.15, height: geo.size.width * 0.15)
                    .position(leftEyePos)
                
                // Right Eye
                let rightEyePos = CGPoint(x: landmarks.rightEye.x * geo.size.width, y: landmarks.rightEye.y * geo.size.height)
                EyeOverlay(params: params)
                    .frame(width: geo.size.width * 0.15, height: geo.size.width * 0.15)
                    .position(rightEyePos)
                
                // Mouth
                let mouthPos = CGPoint(x: landmarks.mouth.x * geo.size.width, y: landmarks.mouth.y * geo.size.height)
                MouthOverlay(params: params)
                    .frame(width: geo.size.width * 0.2, height: geo.size.width * 0.1)
                    .position(mouthPos)
            }
        }
    }
}

struct EyeOverlay: View {
    var params: AnimationParams
    
    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height * (0.2 + params.eyeOpen * 0.8)
            Capsule()
                .fill(params.colorTint)
                .frame(width: geo.size.width, height: height)
                .position(x: geo.size.width/2, y: geo.size.height/2)
                .shadow(color: params.colorTint, radius: 5)
        }
    }
}

struct MouthOverlay: View {
    var params: AnimationParams
    
    var body: some View {
        GeometryReader { geo in
            // Simple arc or line
            Path { p in
                let w = geo.size.width
                let h = geo.size.height
                let start = CGPoint(x: 0, y: h/2)
                let end = CGPoint(x: w, y: h/2)
                
                let smileOffset = params.mouthSmile * h * 0.5
                let openOffset = params.mouthOpen * h * 0.5
                
                p.move(to: start)
                p.addCurve(to: end,
                           control1: CGPoint(x: w/3, y: h/2 + smileOffset + openOffset),
                           control2: CGPoint(x: w*2/3, y: h/2 + smileOffset + openOffset))
                
                if params.mouthOpen > 0.1 {
                    p.addCurve(to: start,
                               control1: CGPoint(x: w*2/3, y: h/2 + smileOffset - openOffset),
                               control2: CGPoint(x: w/3, y: h/2 + smileOffset - openOffset))
                }
            }
            .fill(params.colorTint)
            .shadow(color: params.colorTint, radius: 5)
        }
    }
}
