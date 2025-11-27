import SwiftUI

/// Custom Launch Screen View
/// Displays while app is loading
struct LaunchScreen: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea(.all)
            
            VStack(spacing: 30) {
                // Logo/Icon
                ZStack {
                    // Outer glow ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.cyan, .blue]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 120, height: 120)
                        .blur(radius: 8)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                    
                    // Inner circle
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.cyan.opacity(0.3), .blue.opacity(0.1)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    // Icon
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 50))
                        .foregroundColor(.cyan)
                        .shadow(color: .cyan, radius: 10)
                }
                .scaleEffect(isAnimating ? 1.0 : 0.8)
                
                // App Name
                Text("PCPOS")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .cyan, radius: 5)
                    .opacity(isAnimating ? 1.0 : 0.0)
                
                // Tagline
                Text("Your AI Companion")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                    .opacity(isAnimating ? 0.7 : 0.0)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    LaunchScreen()
}
