import Foundation
import Security

class KeychainService {
    
    static let shared = KeychainService()
    private let service = "com.yourapp.auth"
    
    private init() {}
    
    func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            AppLogger.auth("Не удалось закодировать значение для Keychain", level: .error, metadata: ["key": key])
            return false
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        let success = status == errSecSuccess
        if success {
            AppLogger.auth("Значение сохранено в Keychain", level: .info, metadata: ["key": key])
        } else {
            AppLogger.auth(
                "Ошибка сохранения в Keychain",
                level: .error,
                metadata: ["key": key, "status": "\(status)"]
            )
        }
        return success
    }
    
    func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let value = String(data: data, encoding: .utf8) {
            AppLogger.auth("Значение прочитано из Keychain", level: .debug, metadata: ["key": key])
            return value
        }
        AppLogger.auth(
            "Значение в Keychain не найдено или ошибка чтения",
            level: status == errSecItemNotFound ? .info : .warning,
            metadata: ["key": key, "status": "\(status)"]
        )
        return nil
    }
    
    func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        let success = status == errSecSuccess || status == errSecItemNotFound
        AppLogger.auth(
            success ? "Запись Keychain удалена" : "Ошибка удаления из Keychain",
            level: success ? .info : .warning,
            metadata: ["key": key, "status": "\(status)"]
        )
        return success
    }
}
