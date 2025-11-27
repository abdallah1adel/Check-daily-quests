import SwiftUI

struct SearchOverlayView: View {
    let query: String
    let answer: String
    let sources: [String]
    let onDismiss: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Search results content
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundColor(.cyan)
                    
                    Text("Search Results")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Query
                Text("\"\(query)\"")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal)
                
                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.horizontal)
                
                // Answer
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(answer)
                            .font(.body)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        // Sources
                        if !sources.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Sources:")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                ForEach(sources, id: \ .self) { source in
                                    HStack {
                                        Circle()
                                            .fill(Color.cyan)
                                            .frame(width: 6, height: 6)
                                        Text(source)
                                            .font(.caption)
                                            .foregroundColor(.cyan)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                    }
                }
            }
        }
        .frame(height: UIScreen.main.bounds.height / 2)
        .background(.ultraThinMaterial)
        .clipShape(UnevenRoundedRectangle(cornerRadii: .init(topLeading:  30, bottomLeading:  30, bottomTrailing:  30, topTrailing:  30)))
        .shadow(color: .black.opacity(0.3), radius: 20)
        .overlay(
            UnevenRoundedRectangle(cornerRadii: .init(topLeading:  30, bottomLeading:  30, bottomTrailing:  30, topTrailing:  30))
                .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
        )
        .padding(.top, 60) // Below Dynamic Island
        .scaleEffect(isAnimating ? 1.0 : 0.8)
        .opacity(isAnimating ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea(.all)
        
        SearchOverlayView(
            query: "quantum physics",
            answer: "Quantum physics is the branch of physics that deals with the behavior of matter and energy at the molecular, atomic, nuclear, and even smaller microscopic levels. It fundamentally differs from classical physics in that it describes phenomena that are not observable in everyday life.",
            sources: ["Wikipedia", "Stanford Encyclopedia", "Physics.org"],
            onDismiss: {}
        )
    }
}
