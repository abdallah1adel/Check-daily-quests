import SwiftUI

struct SpeechBubbleView: View {
    let text: String
    let isUser: Bool
    @Binding var isVisible: Bool
    
    var body: some View {
        if isVisible {
            VStack(spacing: 0) {
                // Triangle pointer
                if !isUser {
                    Triangle()
                        .fill(Material.ultraThinMaterial)
                        .frame(width: 20, height: 10)
                        .rotationEffect(.degrees(180))
                        .offset(y: 1) // Overlap slightly
                }
                
                // Bubble Content
                HStack(spacing: 12) {
                    if isUser {
                        Image(systemName: "person.fill")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(8)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                    
                    Text(text)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                    
                    if !isUser {
                        Spacer()
                        Image(systemName: "waveform")
                            .font(.caption)
                            .foregroundColor(.cyan.opacity(0.8))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Material.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.4), .white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                )
                
                // Triangle pointer (User)
                if isUser {
                    Triangle()
                        .fill(Material.ultraThinMaterial)
                        .frame(width: 20, height: 10)
                        .offset(y: -1) // Overlap slightly
                }
            }
            .transition(.scale(scale: 0.8).combined(with: .opacity).combined(with: .move(edge: isUser ? .bottom : .top)))
            .onAppear {
                // Auto-hide after delay based on length
                let duration = max(2.0, Double(text.count) * 0.05)
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    withAnimation {
                        isVisible = false
                    }
                }
            }
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
