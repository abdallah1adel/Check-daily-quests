import SwiftUI

struct WalletView: View {
    @StateObject private var walletManager = WalletManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Balance Card
                    VStack(spacing: 12) {
                        Text("Available Balance")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("$\(String(format: "%.2f", walletManager.availableBalance))")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    .padding(32)
                    .frame(maxWidth: .infinity)
                    .background(
                        UnevenRoundedRectangle(cornerRadii: .init(topLeading:  20, bottomLeading:  20, bottomTrailing:  20, topTrailing:  20))
                            .fill(Color.blue.opacity(0.1))
                    )
                    
                    // Add Funds Button
                    Button(action: {
                        // TODO: Implement add funds flow
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Funds")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .clipShape(UnevenRoundedRectangle(cornerRadii: .init(topLeading:  12, bottomLeading:  12, bottomTrailing:  12, topTrailing:  12)))
                    }
                    
                    // Transactions
                    if walletManager.transactions.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tray")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("No transactions yet")
                                .foregroundColor(.secondary)
                        }
                        .padding(40)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Transactions")
                                .font(.headline)
                            
                            ForEach(walletManager.transactions) { transaction in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(transaction.description)
                                            .font(.body)
                                        Text(transaction.date, style: .date)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text("$\(String(format: "%.2f", transaction.amount))")
                                        .font(.headline)
                                        .foregroundColor(transaction.amount > 0 ? .green : .red)
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .clipShape(UnevenRoundedRectangle(cornerRadii: .init(topLeading:  12, bottomLeading:  12, bottomTrailing:  12, topTrailing:  12)))
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
