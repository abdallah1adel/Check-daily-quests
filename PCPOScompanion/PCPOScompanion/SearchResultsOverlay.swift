import SwiftUI

// MARK: - Search Results Overlay
// Displays AI-powered search results in an overlay

struct SearchResultsOverlay<ViewStateType>: View {
    @Binding var viewState: ViewStateType
    @Binding var showSearchResults: Bool
    let searchQuery: String
    let searchAnswer: String
    let searchSources: [String]
    
    var body: some View {
        if showSearchResults {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text("Search Results")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { showSearchResults = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                
                // Query
                Text("\"\(searchQuery)\"")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .italic()
                
                // Answer
                if !searchAnswer.isEmpty {
                    Text(searchAnswer)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                        )
                }
                
                // Sources
                if !searchSources.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sources")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        ForEach(searchSources, id: \.self) { source in
                            HStack {
                                Image(systemName: "link")
                                    .font(.caption)
                                    .foregroundColor(.cyan)
                                
                                Text(source)
                                    .font(.caption)
                                    .foregroundColor(.cyan)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            .padding()
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
