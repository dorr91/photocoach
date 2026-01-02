import Foundation
@testable import PhotoCoach

class MockKeychainService: KeychainServiceProtocol {
    private var storage: [String: String] = [:]
    private let apiKeyKey = "openai_api_key"
    
    var saveAPIKeyCallCount = 0
    var getAPIKeyCallCount = 0
    var deleteAPIKeyCallCount = 0
    var hasAPIKeyCallCount = 0
    
    var shouldFailSave = false
    var shouldFailDelete = false
    
    func saveAPIKey(_ key: String) -> Bool {
        saveAPIKeyCallCount += 1
        
        if shouldFailSave {
            return false
        }
        
        storage[apiKeyKey] = key
        return true
    }
    
    func getAPIKey() -> String? {
        getAPIKeyCallCount += 1
        return storage[apiKeyKey]
    }
    
    func deleteAPIKey() -> Bool {
        deleteAPIKeyCallCount += 1
        
        if shouldFailDelete {
            return false
        }
        
        storage.removeValue(forKey: apiKeyKey)
        return true
    }
    
    func hasAPIKey() -> Bool {
        hasAPIKeyCallCount += 1
        return storage[apiKeyKey] != nil
    }
    
    // Test helper methods
    func reset() {
        storage.removeAll()
        saveAPIKeyCallCount = 0
        getAPIKeyCallCount = 0
        deleteAPIKeyCallCount = 0
        hasAPIKeyCallCount = 0
        shouldFailSave = false
        shouldFailDelete = false
    }
    
    func setPresetAPIKey(_ key: String) {
        storage[apiKeyKey] = key
    }
}