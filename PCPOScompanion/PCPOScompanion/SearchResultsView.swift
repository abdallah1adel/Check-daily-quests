import SwiftUI

struct SearchResultsView: View {
    let query: String
    let answer: String
    let sources: [String]
    var onDismiss: () -> Void
    
    @State private var animateIn = false
    @State private var offset = CGSize.zero
    
    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.4)
                .ignoresSafeArea(.all)
                .onTapGesture { dismiss() }
            
            // Floating Window
            VStack(spacing: 0) {
                // Window Header (Handle)
                HStack {
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 40, height: 5)
                }
                .frame(height: 24)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.05))
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Query
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.cyan)
                            Text(query)
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        Divider().background(Color.white.opacity(0.2))
                        
                        // Answer
                        Text(answer)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .lineSpacing(6)
                            .padding(.horizontal)
                        
                        // Sources
                        if !sources.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Sources")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                                    .textCase(.uppercase)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(sources, id: \.self) { source in
                                            HStack {
                                                Image(systemName: "link")
                                                    .font(.caption)
                                                Text(source)
                                                    .font(.caption)
                                            }
                                            .padding(8)
                                            .background(Color.white.opacity(0.1))
                                            .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
                    }
                }
            }
            .frame(width: 340, height: 500) // iPad Split View width approx
            .background(Material.regular)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 30, x: 0, y: 10)
            .offset(x: animateIn ? 0 : 400) // Slide in from right
            .offset(y: offset.height) // Drag offset
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = value.translation
                    }
                    .onEnded { value in
                        if abs(value.translation.height) > 100 || value.translation.width > 100 {
                            dismiss()
                        } else {
                            withAnimation(.spring()) {
                                offset = .zero
                            }
                        }
                    }
            )
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                animateIn = true
            }
        }
    }
    
    func dismiss() {
        withAnimation(.easeIn(duration: 0.2)) {
            animateIn = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

// Reusable Flying Island Component
struct FlyingIsland<Content: View>: View {
    let delay: Double
    let animateIn: Bool
    let content: Content
    
    init(delay: Double, animateIn: Bool, @ViewBuilder content: () -> Content) {
        self.delay = delay
        self.animateIn = animateIn
        self.content = content()
    }
    
    var body: some View {
        content
            .offset(y: animateIn ? 0 : 100)
            .opacity(animateIn ? 1 : 0)
            .scaleEffect(animateIn ? 1 : 0.9)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.7).delay(delay),
                value: animateIn
            )
    }
}

// Preview
struct SearchResultsView_Previews: PreviewProvider {
    static var previews: some View {
        SearchResultsView(
            query: "What is the future of AI?",
            answer: "The future of AI involves more generalized intelligence, seamless integration into daily life, and ethical considerations. We are moving towards agents that can reason, plan, and execute complex tasks autonomously.",
            sources: ["techcrunch.com", "openai.com", "wired.com"],
            onDismiss: {}
        )
    }
}
