import SwiftUI

// MARK: - Apple Intelligence Style Search UI

struct AppleIntelligenceSearchView: View {
    @Binding var searchQuery: String
    @Binding var isPresented: Bool
    @State private var animateGradient = false
    @State private var showResults = false
    
    var body: some View {
        ZStack {
            // Apple Intelligence background (translucent blur)
            Color.black.opacity(0.85)
                .ignoresSafeArea(.all)
            
            // Animated gradient orb (like Apple Intelligence)
            AnimatedGradientOrb()
                .frame(width: 300, height: 300)
                .blur(radius: 100)
                .offset(y: animateGradient ? -50 : 50)
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateGradient)
            
            VStack(spacing: 0) {
                // Search bar with Apple Intelligence style
                intelligenceSearchBar
                    .padding(.top, 100)
                    .padding(.horizontal, 20)
                
                if showResults {
                    // Search results with intelligence context
                    intelligenceResults
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
            }
        }
        .onAppear {
            animateGradient = true
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showResults = !searchQuery.isEmpty
            }
        }
        .onChange(of: searchQuery) { query in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                showResults = !query.isEmpty
            }
        }
    }
    
    // MARK: - Intelligence Search Bar
    
    private var intelligenceSearchBar: some View {
        HStack(spacing: 12) {
            // Apple Intelligence icon
            Image(systemName: "sparkles")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(
                    .linearGradient(
                        colors: [.purple, .pink, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.pulse, options: .repeat(.continuous))
                .symbolEffect(.variableColor.iterative)
            
            // Search field
            TextField("Ask me anything...", text: $searchQuery)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white)
                .tint(.white)
            
            // Clear button
            if !searchQuery.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        searchQuery = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            .linearGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        )
    }
    
    // MARK: - Intelligence Results
    
    private var intelligenceResults: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Intelligence context card
                intelligenceContextCard
                
                // Suggested actions
                suggestedActionsGrid
                
                // Search results
                ForEach(0..<3, id: \.self) { index in
                    resultCard(index: index)
                }
            }
            .padding(20)
        }
    }
    
    private var intelligenceContextCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 24))
                    .foregroundStyle(.purple)
                    .symbolEffect(.pulse.byLayer)
                
                Text("Intelligence Summary")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                
                Spacer()
            }
            
            Text("PCPOS is analyzing your query using on-device intelligence and emotion recognition...")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(3)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private var suggestedActionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            actionButton(icon: "mic.fill", title: "Ask", gradient: [.blue, .cyan])
            actionButton(icon: "camera.fill", title: "Scan", gradient: [.purple, .pink])
            actionButton(icon: "wand.and.stars", title: "Create", gradient: [.orange, .yellow])
            actionButton(icon: "brain", title: "Analyze", gradient: [.green, .mint])
        }
    }
    
    private func actionButton(icon: String, title: String, gradient: [Color]) -> some View {
        Button {
            // Action
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .symbolEffect(.bounce, value: searchQuery)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .foregroundStyle(
                .linearGradient(
                    colors: gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
    
    private func resultCard(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Intelligent Result \(index + 1)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
            
            Text("PCPOS found this relevant to your query using emotion analysis and contextual understanding.")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Animated Gradient Orb (Apple Intelligence Style)

struct AnimatedGradientOrb: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    .radialGradient(
                        colors: [.purple.opacity(0.6), .pink.opacity(0.4), .orange.opacity(0.3), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .scaleEffect(animate ? 1.2 : 0.8)
            
            Circle()
                .fill(
                    .radialGradient(
                        colors: [.blue.opacity(0.5), .cyan.opacity(0.3), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .scaleEffect(animate ? 0.8 : 1.1)
                .offset(x: animate ? 30 : -30, y: animate ? -20 : 20)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}
