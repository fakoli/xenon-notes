//
//  KeychainService.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import Foundation
import Security

enum KeychainService {
    enum KeychainError: LocalizedError {
        case saveFailed(OSStatus)
        case retrieveFailed(OSStatus)
        case deleteFailed(OSStatus)
        case dataConversionFailed
        
        var errorDescription: String? {
            switch self {
            case .saveFailed(let status):
                return "Failed to save to keychain: \(status)"
            case .retrieveFailed(let status):
                return "Failed to retrieve from keychain: \(status)"
            case .deleteFailed(let status):
                return "Failed to delete from keychain: \(status)"
            case .dataConversionFailed:
                return "Failed to convert data"
            }
        }
    }
    
    private static let serviceName = "com.xenon.notes"
    
    // MARK: - API Key Management
    
    static func saveAPIKey(_ apiKey: String, for service: APIKeyService) throws {
        let account = service.rawValue
        try save(apiKey: apiKey, account: account)
    }
    
    static func retrieveAPIKey(for service: APIKeyService) throws -> String? {
        let account = service.rawValue
        return try retrieve(account: account)
    }
    
    static func deleteAPIKey(for service: APIKeyService) throws {
        let account = service.rawValue
        try delete(account: account)
    }
    
    // MARK: - Profile-specific API Keys
    
    static func saveProfileAPIKey(_ apiKey: String, profileID: String, service: LLMService) throws {
        let account = "\(service.rawValue)_\(profileID)"
        try save(apiKey: apiKey, account: account)
    }
    
    static func retrieveProfileAPIKey(profileID: String, service: LLMService) throws -> String? {
        let account = "\(service.rawValue)_\(profileID)"
        return try retrieve(account: account)
    }
    
    static func deleteProfileAPIKey(profileID: String, service: LLMService) throws {
        let account = "\(service.rawValue)_\(profileID)"
        try delete(account: account)
    }
    
    // MARK: - Core Keychain Operations
    
    private static func save(apiKey: String, account: String) throws {
        guard let data = apiKey.data(using: .utf8) else {
            throw KeychainError.dataConversionFailed
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
            kSecAttrSynchronizable as String: false
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }
    
    private static func retrieve(account: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrSynchronizable as String: false
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw KeychainError.retrieveFailed(status)
        }
        
        guard let data = result as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            throw KeychainError.dataConversionFailed
        }
        
        return apiKey
    }
    
    private static func delete(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: false
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
    
    // MARK: - Clear All Keys
    
    static func clearAllKeys() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrSynchronizable as String: false
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

// MARK: - API Key Services

enum APIKeyService: String, CaseIterable {
    case deepgram = "deepgram"
    case openAI = "openai"
    case anthropic = "anthropic"
    case gemini = "gemini"
    
    var displayName: String {
        switch self {
        case .deepgram:
            return "Deepgram"
        case .openAI:
            return "OpenAI"
        case .anthropic:
            return "Anthropic"
        case .gemini:
            return "Google Gemini"
        }
    }
}