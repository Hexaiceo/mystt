import Foundation
import Security

/// Keychain manager using the Data Protection Keychain (macOS 10.15+).
/// Unlike the legacy login keychain, the Data Protection Keychain:
/// - Does NOT show password prompts
/// - Uses code signing identity for access control (not per-binary ACLs)
/// - Persists across app updates if the signing identity and bundle ID are stable
class KeychainManager {
    private static let service = "com.mystt.apikeys"

    // MARK: - Core Operations (Data Protection Keychain)

    static func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // Delete existing item first (from both old and new keychains)
        deleteLegacy(key: key)
        deleteDP(key: key)

        // Save to Data Protection Keychain — no password prompts ever
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecUseDataProtectionKeychain as String: true,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecAttrSynchronizable as String: false
        ]
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        if status != errSecSuccess {
            print("[Keychain] Save '\(key)' to DP keychain failed: \(status), trying legacy")
            // Fallback to legacy keychain if DP fails
            return saveLegacy(key: key, data: data)
        }
        return true
    }

    static func load(key: String) -> String? {
        // Try Data Protection Keychain first
        if let value = loadDP(key: key) { return value }
        // Fall back to legacy keychain (for migration)
        return loadLegacy(key: key)
    }

    static func delete(key: String) -> Bool {
        let dp = deleteDP(key: key)
        let legacy = deleteLegacy(key: key)
        return dp || legacy
    }

    // MARK: - Data Protection Keychain

    @discardableResult
    private static func deleteDP(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecUseDataProtectionKeychain as String: true
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    private static func loadDP(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecUseDataProtectionKeychain as String: true,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Legacy Keychain (for migration from old versions)

    private static func saveLegacy(key: String, data: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    private static func loadLegacy(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    private static func deleteLegacy(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Migration

    /// Migrate keys from legacy login keychain to Data Protection Keychain.
    /// This is a one-time operation that moves keys so they never trigger password prompts again.
    static func migrateKeysIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: "keychainMigratedToDP") else { return }

        let allKeys = ["groq_api_key", "groq_stt_api_key", "openai_api_key",
                       "anthropic_api_key", "mistral_api_key", "together_api_key",
                       "perplexity_api_key", "fireworks_api_key"]
        var migrated = 0
        for key in allKeys {
            if let value = loadLegacy(key: key), !value.isEmpty {
                if save(key: key, value: value) {
                    deleteLegacy(key: key)
                    migrated += 1
                }
            }
        }
        UserDefaults.standard.set(true, forKey: "keychainMigratedToDP")
        if migrated > 0 {
            print("[Keychain] Migrated \(migrated) keys to Data Protection Keychain")
        }
    }

    // MARK: - Convenience accessors

    static var groqAPIKey: String? {
        get { load(key: "groq_api_key") }
        set {
            if let v = newValue {
                _ = save(key: "groq_api_key", value: v)
                _ = save(key: "groq_stt_api_key", value: v)
            } else {
                _ = delete(key: "groq_api_key")
                _ = delete(key: "groq_stt_api_key")
            }
        }
    }

    static var openaiAPIKey: String? {
        get { load(key: "openai_api_key") }
        set { if let v = newValue { _ = save(key: "openai_api_key", value: v) } else { _ = delete(key: "openai_api_key") } }
    }

    static var groqSTTAPIKey: String? {
        get { load(key: "groq_api_key") ?? load(key: "groq_stt_api_key") }
    }
}
