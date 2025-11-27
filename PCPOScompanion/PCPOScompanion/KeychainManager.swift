import Foundation
import Security

enum KeychainError: Error {
    case duplicateEntry
    case unknown(OSStatus)
    case itemNotFound
    case invalidItemFormat
    case unexpectedStatus(OSStatus)
}

class KeychainManager {
    static let shared = KeychainManager()
    private let serviceName = "com.megaman.companion.keys"
    
    private init() {}
    
    // MARK: - Save
    
    func save(_ data: Data, service: String, account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            // Item already exists, thus update it.
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account
            ]
            
            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: data
            ]
            
            let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            if status != errSecSuccess {
                throw KeychainError.unexpectedStatus(status)
            }
        } else if status != errSecSuccess {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    func save(_ string: String, service: String, account: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.invalidItemFormat
        }
        try save(data, service: service, account: account)
    }
    
    // MARK: - Read
    
    func read(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess {
            return item as? Data
        }
        return nil
    }
    
    func readString(service: String, account: String) -> String? {
        guard let data = read(service: service, account: account) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - Delete
    
    func delete(service: String, account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}
