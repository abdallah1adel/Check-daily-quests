import SwiftUI

struct ConsentView: View {
    @ObservedObject var learningService = LearningGraphService.shared
    @Environment(\.dismiss) var dismiss
    @State private var exportedGraph: EncryptedGraph?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .font(.largeTitle)
                                .foregroundColor(.blue)
                            Text("Help PCPOS Learn")
                                .font(.title.bold())
                        }
                        
                        Text("Contribute to collective model improvement while keeping your privacy intact")
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom)
                    
                    // What's Shared
                    VStack(alignment: .leading, spacing: 12) {
                        Label("What's Shared", systemImage: "checkmark.shield.fill")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        PrivacyRow(icon: "chart.line.uptrend.xyaxis", text: "Interaction patterns (question types, complexity)")
                        PrivacyRow(icon: "face.smiling", text: "Emotional context (generalized, bucketed)")
                        PrivacyRow(icon: "speedometer", text: "Model performance metrics")
                        PrivacyRow(icon: "arrow.triangle.branch", text: "Which model worked best")
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .clipShape(UnevenRoundedRectangle(cornerRadii: .init(topLeading:  12, bottomLeading:  12, bottomTrailing:  12, topTrailing:  12)))
                    
                    // What's Never Shared
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Never Shared", systemImage: "lock.shield.fill")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        PrivacyRow(icon: "text.bubble", text: "Your actual conversation text", isNever: true)
                        PrivacyRow(icon: "person", text: "Your name or identity", isNever: true)
                        PrivacyRow(icon: "location", text: "Location or device info", isNever: true)
                        PrivacyRow(icon: "waveform", text: "Audio or camera data", isNever: true)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .clipShape(UnevenRoundedRectangle(cornerRadii: .init(topLeading:  12, bottomLeading:  12, bottomTrailing:  12, topTrailing:  12)))
                    
                    // Privacy Guarantee
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Privacy Guarantee", systemImage: "hand.raised.fill")
                            .font(.headline)
                        
                        Text("We use **differential privacy** - mathematical noise is added to prevent reverse-engineering your patterns. Even if someone accessed the database, they couldn't reconstruct your conversations.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .clipShape(UnevenRoundedRectangle(cornerRadii: .init(topLeading:  12, bottomLeading:  12, bottomTrailing:  12, topTrailing:  12)))
                    
                    // Stats (if available)
                    if learningService.hasOptedIn, let graph = exportedGraph {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Contribution")
                                .font(.headline)
                            
                            HStack {
                                ConsentStatView(value: "\(graph.deviceIdHash.prefix(8))...", label: "Device ID (anonymized)")
                                Spacer()
                                if learningService.pendingUpload {
                                    Label("Ready to upload", systemImage: "arrow.up.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(UnevenRoundedRectangle(cornerRadii: RectangleCornerRadii(topLeading: 12, bottomLeading: 12, bottomTrailing: 12, topTrailing: 12)))
                    }
                    
                    // Opt-in/out Toggle
                    Toggle(isOn: $learningService.hasOptedIn) {
                        VStack(alignment: .leading) {
                            Text("Participate in Federated Learning")
                                .font(.headline)
                            Text("You can change this anytime in Settings")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .clipShape(UnevenRoundedRectangle(cornerRadii: .init(topLeading:  12, bottomLeading:  12, bottomTrailing:  12, topTrailing:  12)))
                }
                .padding()
            }
            .navigationTitle("Federated Learning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PrivacyRow: View {
    let icon: String
    let text: String
    var isNever: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(isNever ? .red : .green)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
            Spacer()
            if isNever {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }
}

struct ConsentStatView: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ConsentView()
}
