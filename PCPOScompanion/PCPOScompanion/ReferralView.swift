import SwiftUI
import UIKit

struct ReferralView: View {
    @StateObject private var referralManager = ReferralManager.shared
    @State private var showCopied = false
    @State private var showShare = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.cyan)
                        .shadow(color: .cyan, radius: 10)
                    
                    Text("Invite Friends, Save Money!")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Get $7.99/month off for every friend who subscribes")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Referral Code Card
                VStack(spacing: 15) {
                    Text("Your Referral Code")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if let code = referralManager.userReferralCode {
                        HStack {
                            Text(code)
                                .font(.system(.title2, design: .monospaced))
                                .fontWeight(.bold)
                                .kerning(2)
                            
                            Button(action: { copyCode() }) {
                                Image(systemName: showCopied ? "checkmark.circle.fill" : "doc.on.doc")
                                    .foregroundColor(showCopied ? .green : .blue)
                                    .font(.title3)
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .clipShape(UnevenRoundedRectangle(cornerRadii: .init(topLeading:  10, bottomLeading:  10, bottomTrailing:  10, topTrailing:  10)))
                        
                        Button(action: { showShare = true }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Code")
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)
                        
                    } else {
                        ProgressView("Loading your code...")
                            .tint(.cyan)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .clipShape(UnevenRoundedRectangle(cornerRadii: .init(topLeading:  15, bottomLeading:  15, bottomTrailing:  15, topTrailing:  15)))
                
                // Benefits
                VStack(alignment: .leading, spacing: 15) {
                    Text("How It Works")
                        .font(.headline)
                        .padding(.bottom, 5)
                    
                    BenefitRow(
                        icon: "1.circle.fill",
                        text: "Share your code with friends",
                        color: .blue
                    )
                    BenefitRow(
                        icon: "2.circle.fill",
                        text: "They get 10% off their first month",
                        color: .green
                    )
                    BenefitRow(
                        icon: "3.circle.fill",
                        text: "You save $7.99/month for each active referral",
                        color: .purple
                    )
                    BenefitRow(
                        icon: "infinity.circle.fill",
                        text: "Unlimited referrals = Maximum savings!",
                        color: .cyan
                    )
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .clipShape(UnevenRoundedRectangle(cornerRadii: .init(topLeading:  15, bottomLeading:  15, bottomTrailing:  15, topTrailing:  15)))
                
                // Stats
                if referralManager.totalReferrals > 0 {
                    VStack(spacing: 15) {
                        Text("Your Impact 🎉")
                            .font(.headline)
                        
                        HStack(spacing: 30) {
                            StatView(
                                label: "Total",
                                value: "\(referralManager.totalReferrals)",
                                color: .blue
                            )
                            StatView(
                                label: "Active",
                                value: "\(referralManager.activeReferrals)",
                                color: .green
                            )
                            StatView(
                                label: "$/month",
                                value: String(format: "%.2f", referralManager.currentDiscount),
                                color: .purple
                            )
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green.opacity(0.2), Color.cyan.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(UnevenRoundedRectangle(cornerRadii: .init(topLeading:  15, bottomLeading:  15, bottomTrailing:  15, topTrailing:  15)))
                }
                
                Spacer(minLength: 20)
            }
            .padding()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .onAppear {
            Task {
                let userId = getCurrentUserId()
                try? await referralManager.generateReferralCode(userId: userId)
                try? await referralManager.loadReferralStats(userId: userId)
            }
        }
        .sheet(isPresented: $showShare) {
            if let code = referralManager.userReferralCode {
                ShareSheet(items: [
                    "Join me on PCPOS Companion and get 10% off! Use my code: \(code)"
                ])
            }
        }
    }
    
    func copyCode() {
        if let code = referralManager.userReferralCode {
            UIPasteboard.general.string = code
            withAnimation {
                showCopied = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showCopied = false
                }
            }
            PCPOSHaptics.shared.playSuccess()
        }
    }
}

struct BenefitRow: View {
    var icon: String
    var text: String
    var color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 30)
            
            Text(text)
                .foregroundColor(.white)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

struct StatView: View {
    var label: String
    var value: String
    var color: Color
    
    var body: some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

// Share Sheet Helper
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Helper function to get current user ID (implement based on your auth system)
func getCurrentUserId() -> String {
    // TODO: Replace with actual user ID from your auth system
    // For now, use device identifier
    return UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
}
