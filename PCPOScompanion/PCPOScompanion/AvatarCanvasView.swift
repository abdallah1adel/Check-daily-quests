import SwiftUI

struct AvatarCanvasView: View {
    var params: AnimationParams
    
    var body: some View {
        ZStack {
            // Outer Glow
            Circle()
                .fill(params.colorTint)
                .blur(radius: 20)
                .scaleEffect(1.0 + params.glow * 0.2)
                .opacity(0.6)
            
            // Core Circle
            Circle()
                .fill(LinearGradient(gradient: Gradient(colors: [params.colorTint, Color.white]), startPoint: .bottomLeading, endPoint: .topTrailing))
                .overlay(
                    Circle().stroke(Color.white.opacity(0.8), lineWidth: 2)
                )
                .shadow(color: params.colorTint, radius: 10)
            
            // "Digital" Eyes (Simple shapes)
            HStack(spacing: 40) {
                Capsule()
                    .fill(Color.white)
                    .frame(width: 20, height: 30 * params.eyeOpen)
                    .shadow(color: .white, radius: 5)
                
                Capsule()
                    .fill(Color.white)
                    .frame(width: 20, height: 30 * params.eyeOpen)
                    .shadow(color: .white, radius: 5)
            }
            .offset(y: -10)
            
            // "Digital" Mouth (Waveform-like)
            UnevenRoundedRectangle(cornerRadii: .init(topLeading:  5, bottomLeading:  5, bottomTrailing:  5, topTrailing:  5))
                .fill(Color.white.opacity(0.8))
                .frame(width: 40 + (params.mouthSmile * 20), height: 4 + (params.mouthOpen * 20))
                .offset(y: 30)
        }
        .padding()
    }
}

#Preview {
    AvatarCanvasView(params: AnimationParams())
        .frame(width: 200, height: 200)
        .background(Color.black)
}
