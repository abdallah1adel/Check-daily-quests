import SwiftUI
import StoreKit

struct PaywallView: View {
    @ObservedObject var storeManager = StoreManager.shared
    @StateObject private var referralManager = ReferralManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var promoCode: String = ""
    @State private var appliedDiscount: Double? = nil
    @State private var discountError: String? = nil
    @State private var isValidating = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.blue.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(.all)
            
            VStack(spacing: 20) {
                // Header
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 80))
                    .foregroundColor(.cyan)
                    .shadow(color: .cyan, radius: 10)
                    .padding(.top, 40)
                
                Text("Upgrade Your PCPOS")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Unlock the full potential of your AI companion.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                // Features List
                VStack(alignment: .leading, spacing: 15) {
                    FeatureRow(icon: "sparkles", text: "Real AI Intelligence (OpenAI)")
                    FeatureRow(icon: "network", text: "Web Search Capability")
                    FeatureRow(icon: "bubble.left.and.bubble.right.fill", text: "Unlimited Conversations")
                    FeatureRow(icon: "heart.fill", text: "Advanced Emotional Engine")
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .clipShape(UnevenRoundedRectangle(cornerRadii: .init(topLeading:  15, bottomLeading:  15, bottomTrailing:  15, topTrailing:  15)))
                .padding(.horizontal)
                
                // Promo Code Section
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        TextField("Promo or Referral Code", text: $promoCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.allCharacters)
                            .disabled(isValidating)
                        
                        Button(action: { Task { await validateAndApplyCode() }}) {
                            if isValidating {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Text("Apply")
                                    .fontWeight(.semibold)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)
                        .disabled(promoCode.isEmpty || isValidating)
                    }
                    .padding(.horizontal)
                    
                    if let discount = appliedDiscount {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text(discount < 1 ? "🎉 \(Int(discount * 100))% off applied!" : "🎉 $\(String(format: "%.2f", discount)) off applied!")
                        }
                        .foregroundColor(.green)
                        .font(.caption)
                    } else if let error = discountError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                            Text(error)
                        }
                        .foregroundColor(.red)
                        .font(.caption)
                    }
                }
                
                Spacer()
                
                // Products
                if storeManager.products.isEmpty {
                    ProgressView("Loading Shop...")
                        .foregroundColor(.white)
                } else {
                    ForEach(storeManager.products) { product in
                        Button(action: {
                            Task {
                                try? await storeManager.purchase(product)
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(product.displayName)
                                        .font(.headline)
                                    Text(product.description)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Text(product.displayPrice)
                                    .fontWeight(.bold)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.2))
                            .clipShape(UnevenRoundedRectangle(cornerRadii: .init(topLeading:  10, bottomLeading:  10, bottomTrailing:  10, topTrailing:  10)))
                            .overlay(
                                UnevenRoundedRectangle(cornerRadii: .init(topLeading:  10, bottomLeading:  10, bottomTrailing:  10, topTrailing:  10))
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    }
                }
                
                // Restore Button
                Button("Restore Purchases") {
                    Task {
                        try? await AppStore.sync()
                    }
                }
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.bottom, 20)
            }
        }
        .overlay(
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.5))
                    .padding()
            }
            , alignment: .topTrailing
        )
    }
    
    func validateAndApplyCode() async {
        guard !promoCode.isEmpty else { return }
        
        isValidating = true
        discountError = nil
        appliedDiscount = nil
        
        do {
            let result = try await referralManager.validateCode(promoCode, userId: getCurrentUserId())
            
            if result.valid {
                if let discount = result.discount {
                    // Apply discount
                    if discount.type == "PERCENTAGE" {
                        appliedDiscount = discount.value / 100 // Convert to decimal
                    } else {
                        appliedDiscount = discount.value
                    }
                    PCPOSHaptics.shared.playSuccess()
                }
            } else {
                discountError = result.error ?? "Invalid code"
                PCPOSHaptics.shared.playError()
            }
        } catch {
            discountError = "Failed to validate code"
            PCPOSHaptics.shared.playError()
        }
        
        isValidating = false
    }
}

struct FeatureRow: View {
    var icon: String
    var text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.cyan)
                .frame(width: 30)
            Text(text)
                .foregroundColor(.white)
            Spacer()
        }
    }
}
