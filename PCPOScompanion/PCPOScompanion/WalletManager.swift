import Foundation
import Combine

// MARK: - Wallet Manager
// Manages user wallet balance and transactions

@MainActor
class WalletManager: ObservableObject {
    static let shared = WalletManager()
    
    @Published var availableBalance: Double = 0.0
    @Published var transactions: [WalletTransaction] = []
    
    private init() {
        loadBalance()
    }
    
    private func loadBalance() {
        // Load from UserDefaults or backend
        availableBalance = UserDefaults.standard.double(forKey: "wallet_balance")
    }
    
    func addFunds(amount: Double) {
        availableBalance += amount
        saveBalance()
    }
    
    func deductFunds(amount: Double) -> Bool {
        guard availableBalance >= amount else { return false }
        availableBalance -= amount
        saveBalance()
        return true
    }
    
    private func saveBalance() {
        UserDefaults.standard.set(availableBalance, forKey: "wallet_balance")
    }
}

struct WalletTransaction: Identifiable {
    let id = UUID()
    let amount: Double
    let date: Date
    let description: String
}
