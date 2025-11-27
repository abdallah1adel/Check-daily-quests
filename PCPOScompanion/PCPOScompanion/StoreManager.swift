import Foundation
import StoreKit
import Combine

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    @Published var products: [Product] = []
    @Published var isProAccess: Bool = false
    @Published var purchasedProductIDs: Set<String> = []
    
    private var updates: Task<Void, Never>? = nil
    
    private let productDict: [String: String] = [
        "com.PCPOScompanion.pro.monthly": "PCPOS Pro (Monthly)",
        "com.PCPOScompanion.pro.yearly": "PCPOS Pro (Yearly)"
    ]
    
    init() {
        // Initialize trial if not set
        if UserDefaults.standard.object(forKey: "firstLaunchDate") == nil {
            UserDefaults.standard.set(Date(), forKey: "firstLaunchDate")
        }
        
        updates = newTransactionListenerTask()
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
    }
    
    var isTrialActive: Bool {
        guard let firstLaunch = UserDefaults.standard.object(forKey: "firstLaunchDate") as? Date else { return false }
        return Date().timeIntervalSince(firstLaunch) < 604800 // 7 days = 604800 seconds
    }
    
    deinit {
        updates?.cancel()
    }
    
    func requestProducts() async {
        do {
            let storeProducts = try await Product.products(for: productDict.keys)
            self.products = storeProducts.sorted(by: { $0.price < $1.price })
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateCustomerProductStatus()
            await transaction.finish()
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }
    
    func updateCustomerProductStatus() async {
        var purchased: Set<String> = []
        
        // Iterate through all of the user's purchased products
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Check if subscription is valid/active
                if transaction.revocationDate == nil {
                    purchased.insert(transaction.productID)
                }
            } catch {
                print("Transaction verification failed")
            }
        }
        
        self.purchasedProductIDs = purchased
        // Pro access if purchased OR trial is active
        self.isProAccess = !purchased.isEmpty || isTrialActive
    }
    
    nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    private func newTransactionListenerTask() -> Task<Void, Never> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updateCustomerProductStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification")
                }
            }
        }
    }
    
    enum StoreError: Error {
        case failedVerification
    }
}
