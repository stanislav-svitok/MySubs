//
//  Keychain+Extensions.swift
//  MySubs
//
//  Created by Stanislav Svitok on 22/01/2025.
//

import Security
import Foundation

struct Keychain {
    enum Tag: String {
        case login = "com.svitok.stanislav.MySubs.login"
    }
    
    enum GeneralError: Error {
        case osStatus(OSStatus)
    }
    
    private static func clear(tag: Tag) {
        let query: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: tag.rawValue,
                    kSecAttrAccount as String: tag.rawValue
                ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    private static func set(_ value: String, for tag: Tag) throws {
        clear(tag: tag)
        let query: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: tag.rawValue,
                    kSecAttrAccount as String: tag.rawValue,
                    kSecValueData as String: value.data(using: .utf8)!
                ]
        

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw GeneralError.osStatus(status) }
    }
    
    private static func get(_ tag: Tag) throws -> String {
        let query: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: tag.rawValue,
                    kSecAttrAccount as String: tag.rawValue,
                    kSecReturnData as String: true,
                    kSecMatchLimit as String: kSecMatchLimitOne
                ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let retrievedData = item as? Data,
              let value = String(data: retrievedData, encoding: .utf8)
        else { throw GeneralError.osStatus(status) }
        
        return value
    }
    
    
    private static func delete(service: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    static var storedToken: String? {
        try? get(.login)
    }
    
    static func storeLoginToken(_ token: String) throws {
        try set(token, for: .login)
    }
    
    static func clearLoginToken() throws {
        clear(tag: .login)
    }
}
