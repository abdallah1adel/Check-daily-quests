import Foundation
import Combine

@MainActor
class ReferralManager: ObservableObject {
    static let shared = ReferralManager()
    
    @Published var userReferralCode: String? = nil
    @Published var totalReferrals: Int = 0
    @Published var activeReferrals: Int = 0
    @Published var currentDiscount: Double = 0.0
    @Published var appliedPromoCode: String? = nil
    @Published var promoDiscount: Double? = nil
    
    private var baseURL: String {
        // Check environment or use default
        if let url = ProcessInfo.processInfo.environment["BACKEND_URL"] {
            return url
        }
        return "http://localhost:3000/api" // Default for development
    }
    
    private init() {}
    
    // Generate referral code for user
    func generateReferralCode(userId: String) async throws {
        guard let url = URL(string: "\(baseURL)/referrals/generate") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["userId": userId]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ReferralCodeResponse.self, from: data)
        
        DispatchQueue.main.async {
            self.userReferralCode = response.code
        }
    }
    
    // Validate referral or promo code
    func validateCode(_ code: String, userId: String?) async throws -> CodeValidationResult {
        guard let url = URL(string: "\(baseURL)/referrals/validate") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = ["code": code.uppercased()]
        if let userId = userId {
            body["userId"] = userId
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let result = try JSONDecoder().decode(CodeValidationResult.self, from: data)
        
        // Store discount if valid
        if result.valid, let discount = result.discount {
            DispatchQueue.main.async {
                self.appliedPromoCode = code
                self.promoDiscount = discount.value
            }
        }
        
        return result
    }
    
    // Apply referral code when new user subscribes
    func applyReferralCode(_ code: String, userId: String) async throws {
        guard let url = URL(string: "\(baseURL)/referrals/apply") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["referralCode": code.uppercased(), "refereeId": userId]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ApplyReferralResponse.self, from: data)
        
        if response.success {
            print("✅ Referral applied successfully!")
        }
    }
    
    // Redeem promo code
    func redeemPromoCode(_ code: String, userId: String) async throws {
        guard let url = URL(string: "\(baseURL)/referrals/redeem-promo") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["code": code.uppercased(), "userId": userId]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(RedeemPromoResponse.self, from: data)
        
        if response.success {
            print("✅ Promo code redeemed successfully!")
        }
    }
    
    // Get user's referral statistics
    func loadReferralStats(userId: String) async throws {
        guard let url = URL(string: "\(baseURL)/referrals/stats/\(userId)") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let stats = try JSONDecoder().decode(ReferralStats.self, from: data)
        
        DispatchQueue.main.async {
            self.userReferralCode = stats.code
            self.totalReferrals = stats.totalReferrals
            self.activeReferrals = stats.activeReferrals ?? 0
            self.currentDiscount = stats.currentDiscount
        }
    }
}

// MARK: - Response Models

struct ReferralCodeResponse: Codable {
    let code: String
    let shareUrl: String
}

struct CodeValidationResult: Codable {
    let valid: Bool
    let type: String?
    let error: String?
    let discount: DiscountInfo?
}

struct DiscountInfo: Codable {
    let type: String
    let value: Double
    let duration: String
}

struct ApplyReferralResponse: Codable {
    let success: Bool
    let referrerId: String?
    let discountApplied: Bool
}

struct RedeemPromoResponse: Codable {
    let success: Bool
    let discount: DiscountInfo?
}

struct ReferralStats: Codable {
    let code: String?
    let totalReferrals: Int
    let activeReferrals: Int?
    let currentDiscount: Double
    let savings: Double
}
