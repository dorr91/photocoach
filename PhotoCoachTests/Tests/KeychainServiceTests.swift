import XCTest
@testable import PhotoCoach

final class KeychainServiceTests: XCTestCase {
    var keychainService: KeychainService!
    
    override func setUpWithError() throws {
        keychainService = KeychainService()
        
        // Clean up any existing API key from previous tests
        _ = keychainService.deleteAPIKey()
    }
    
    override func tearDownWithError() throws {
        // Clean up after each test
        _ = keychainService.deleteAPIKey()
        keychainService = nil
    }
    
    // MARK: - Save API Key Tests
    
    func test_saveAPIKey_withValidKey_shouldReturnTrue() {
        // Given
        let testAPIKey = "sk-test1234567890abcdefghijklmnopqrstuvwxyz"
        
        // When
        let result = keychainService.saveAPIKey(testAPIKey)
        
        // Then
        XCTAssertTrue(result, "Should successfully save valid API key")
    }
    
    func test_saveAPIKey_withEmptyKey_shouldReturnFalse() {
        // Given
        let emptyAPIKey = ""
        
        // When
        let result = keychainService.saveAPIKey(emptyAPIKey)
        
        // Then
        XCTAssertFalse(result, "Should fail to save empty API key")
    }
    
    func test_saveAPIKey_multipleKeys_shouldOverwritePrevious() {
        // Given
        let firstKey = "sk-first-key-12345"
        let secondKey = "sk-second-key-67890"
        
        // When
        let firstResult = keychainService.saveAPIKey(firstKey)
        let secondResult = keychainService.saveAPIKey(secondKey)
        
        // Then
        XCTAssertTrue(firstResult, "Should save first key")
        XCTAssertTrue(secondResult, "Should save second key")
        
        let retrievedKey = keychainService.getAPIKey()
        XCTAssertEqual(retrievedKey, secondKey, "Should retrieve the latest saved key")
    }
    
    // MARK: - Get API Key Tests
    
    func test_getAPIKey_whenKeyExists_shouldReturnKey() {
        // Given
        let testAPIKey = "sk-test-api-key-12345"
        let saveResult = keychainService.saveAPIKey(testAPIKey)
        XCTAssertTrue(saveResult, "Setup: Should save test key")
        
        // When
        let retrievedKey = keychainService.getAPIKey()
        
        // Then
        XCTAssertEqual(retrievedKey, testAPIKey, "Should retrieve the correct API key")
    }
    
    func test_getAPIKey_whenNoKeyExists_shouldReturnNil() {
        // Given - No API key saved
        
        // When
        let retrievedKey = keychainService.getAPIKey()
        
        // Then
        XCTAssertNil(retrievedKey, "Should return nil when no API key exists")
    }
    
    func test_getAPIKey_afterDeletion_shouldReturnNil() {
        // Given
        let testAPIKey = "sk-test-api-key-67890"
        _ = keychainService.saveAPIKey(testAPIKey)
        _ = keychainService.deleteAPIKey()
        
        // When
        let retrievedKey = keychainService.getAPIKey()
        
        // Then
        XCTAssertNil(retrievedKey, "Should return nil after key deletion")
    }
    
    // MARK: - Delete API Key Tests
    
    func test_deleteAPIKey_whenKeyExists_shouldReturnTrue() {
        // Given
        let testAPIKey = "sk-test-api-key-delete"
        let saveResult = keychainService.saveAPIKey(testAPIKey)
        XCTAssertTrue(saveResult, "Setup: Should save test key")
        
        // When
        let deleteResult = keychainService.deleteAPIKey()
        
        // Then
        XCTAssertTrue(deleteResult, "Should successfully delete existing key")
        
        // Verify deletion
        let retrievedKey = keychainService.getAPIKey()
        XCTAssertNil(retrievedKey, "Key should be deleted")
    }
    
    func test_deleteAPIKey_whenNoKeyExists_shouldReturnTrue() {
        // Given - No API key exists
        
        // When
        let deleteResult = keychainService.deleteAPIKey()
        
        // Then
        XCTAssertTrue(deleteResult, "Should return true even when no key exists (idempotent)")
    }
    
    func test_deleteAPIKey_multipleCalls_shouldBeIdempotent() {
        // Given
        let testAPIKey = "sk-test-idempotent-key"
        _ = keychainService.saveAPIKey(testAPIKey)
        
        // When
        let firstDelete = keychainService.deleteAPIKey()
        let secondDelete = keychainService.deleteAPIKey()
        let thirdDelete = keychainService.deleteAPIKey()
        
        // Then
        XCTAssertTrue(firstDelete, "First deletion should succeed")
        XCTAssertTrue(secondDelete, "Second deletion should be idempotent")
        XCTAssertTrue(thirdDelete, "Third deletion should be idempotent")
    }
    
    // MARK: - Has API Key Tests
    
    func test_hasAPIKey_whenKeyExists_shouldReturnTrue() {
        // Given
        let testAPIKey = "sk-test-has-key-check"
        let saveResult = keychainService.saveAPIKey(testAPIKey)
        XCTAssertTrue(saveResult, "Setup: Should save test key")
        
        // When
        let hasKey = keychainService.hasAPIKey()
        
        // Then
        XCTAssertTrue(hasKey, "Should return true when API key exists")
    }
    
    func test_hasAPIKey_whenNoKeyExists_shouldReturnFalse() {
        // Given - No API key exists
        
        // When
        let hasKey = keychainService.hasAPIKey()
        
        // Then
        XCTAssertFalse(hasKey, "Should return false when no API key exists")
    }
    
    func test_hasAPIKey_afterDeletion_shouldReturnFalse() {
        // Given
        let testAPIKey = "sk-test-has-key-after-delete"
        _ = keychainService.saveAPIKey(testAPIKey)
        _ = keychainService.deleteAPIKey()
        
        // When
        let hasKey = keychainService.hasAPIKey()
        
        // Then
        XCTAssertFalse(hasKey, "Should return false after key deletion")
    }
    
    // MARK: - Integration Tests
    
    func test_fullWorkflow_saveGetDeleteCheck() {
        // Given
        let testAPIKey = "sk-full-workflow-test-123"
        
        // Initial state - no key
        XCTAssertFalse(keychainService.hasAPIKey(), "Should start with no API key")
        XCTAssertNil(keychainService.getAPIKey(), "Should return nil initially")
        
        // Save key
        let saveResult = keychainService.saveAPIKey(testAPIKey)
        XCTAssertTrue(saveResult, "Should save API key successfully")
        
        // Check existence
        XCTAssertTrue(keychainService.hasAPIKey(), "Should have API key after saving")
        
        // Retrieve key
        let retrievedKey = keychainService.getAPIKey()
        XCTAssertEqual(retrievedKey, testAPIKey, "Should retrieve correct API key")
        
        // Delete key
        let deleteResult = keychainService.deleteAPIKey()
        XCTAssertTrue(deleteResult, "Should delete API key successfully")
        
        // Final state - no key
        XCTAssertFalse(keychainService.hasAPIKey(), "Should have no API key after deletion")
        XCTAssertNil(keychainService.getAPIKey(), "Should return nil after deletion")
    }
    
    func test_multipleKeySaves_shouldMaintainLatest() {
        // Given
        let keys = [
            "sk-key-1-12345",
            "sk-key-2-67890", 
            "sk-key-3-abcdef",
            "sk-key-4-final"
        ]
        
        // When - Save multiple keys
        for key in keys {
            let result = keychainService.saveAPIKey(key)
            XCTAssertTrue(result, "Should save key: \(key)")
        }
        
        // Then - Should have the latest key
        XCTAssertTrue(keychainService.hasAPIKey(), "Should have an API key")
        let finalKey = keychainService.getAPIKey()
        XCTAssertEqual(finalKey, keys.last, "Should have the latest saved key")
    }
    
    // MARK: - Edge Cases
    
    func test_saveAPIKey_withVeryLongKey_shouldHandle() {
        // Given
        let longKey = String(repeating: "a", count: 1000) + "sk-very-long-key"
        
        // When
        let result = keychainService.saveAPIKey(longKey)
        
        // Then
        XCTAssertTrue(result, "Should handle very long API keys")
        
        let retrievedKey = keychainService.getAPIKey()
        XCTAssertEqual(retrievedKey, longKey, "Should retrieve long key correctly")
    }
    
    func test_saveAPIKey_withSpecialCharacters_shouldHandle() {
        // Given
        let specialKey = "sk-test-!@#$%^&*()_+-={}[]|\\:;\"'<>?,./"
        
        // When
        let result = keychainService.saveAPIKey(specialKey)
        
        // Then
        XCTAssertTrue(result, "Should handle keys with special characters")
        
        let retrievedKey = keychainService.getAPIKey()
        XCTAssertEqual(retrievedKey, specialKey, "Should retrieve special character key correctly")
    }
    
    func test_saveAPIKey_withUnicodeCharacters_shouldHandle() {
        // Given
        let unicodeKey = "sk-test-🔑-emoji-key-测试"
        
        // When
        let result = keychainService.saveAPIKey(unicodeKey)
        
        // Then
        XCTAssertTrue(result, "Should handle keys with Unicode characters")
        
        let retrievedKey = keychainService.getAPIKey()
        XCTAssertEqual(retrievedKey, unicodeKey, "Should retrieve Unicode key correctly")
    }
    
    // MARK: - Performance Tests
    
    func test_saveAndRetrieve_performance() {
        let testKey = "sk-performance-test-key-12345"
        
        measure {
            for _ in 0..<100 {
                _ = keychainService.saveAPIKey(testKey)
                _ = keychainService.getAPIKey()
                _ = keychainService.hasAPIKey()
            }
        }
    }
    
    func test_bulkOperations_performance() {
        measure {
            for i in 0..<50 {
                let key = "sk-bulk-test-\(i)"
                _ = keychainService.saveAPIKey(key)
                _ = keychainService.hasAPIKey()
                _ = keychainService.getAPIKey()
                _ = keychainService.deleteAPIKey()
            }
        }
    }
    
    // MARK: - Concurrent Access Tests
    
    func test_concurrentAccess_shouldBeThreadSafe() async {
        // Given
        let testKey = "sk-concurrent-test-key"
        
        // When - Perform concurrent operations
        await withTaskGroup(of: Void.self) { group in
            // Save operations
            for i in 0..<10 {
                group.addTask {
                    _ = self.keychainService.saveAPIKey("\(testKey)-\(i)")
                }
            }
            
            // Read operations
            for _ in 0..<10 {
                group.addTask {
                    _ = self.keychainService.getAPIKey()
                    _ = self.keychainService.hasAPIKey()
                }
            }
            
            // Delete operations
            for _ in 0..<5 {
                group.addTask {
                    _ = self.keychainService.deleteAPIKey()
                }
            }
        }
        
        // Then - Should not crash and final state should be consistent
        // The exact final state is non-deterministic due to concurrency,
        // but the operations should not crash
        let hasKey = keychainService.hasAPIKey()
        let retrievedKey = keychainService.getAPIKey()
        
        if hasKey {
            XCTAssertNotNil(retrievedKey, "If hasKey is true, getAPIKey should return a key")
        } else {
            XCTAssertNil(retrievedKey, "If hasKey is false, getAPIKey should return nil")
        }
    }
}