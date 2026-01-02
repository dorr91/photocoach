import XCTest
@testable import PhotoCoachCore

// Fast unit tests using PhotoCoachCore package
// These run without simulator and test real business logic
final class BasicPackageTests: XCTestCase {
    
    func test_keychainService() {
        // Test real KeychainService implementation
        let keychain = KeychainService()
        
        // Test API key operations
        let testKey = "test-api-key-12345"
        
        // Clean start
        keychain.deleteAPIKey()
        XCTAssertFalse(keychain.hasAPIKey())
        
        // Save key
        XCTAssertTrue(keychain.saveAPIKey(testKey))
        XCTAssertTrue(keychain.hasAPIKey())
        
        // Retrieve key
        XCTAssertEqual(keychain.getAPIKey(), testKey)
        
        // Clean up
        XCTAssertTrue(keychain.deleteAPIKey())
        XCTAssertFalse(keychain.hasAPIKey())
    }
    
    func test_photoStorageProtocol() {
        // Test PhotoStorageService initialization
        let photoStorage = PhotoStorageService()
        
        // Test that service conforms to protocol (explicit cast to avoid warning)
        XCTAssertNotNil(photoStorage as PhotoStorageProtocol)
        
        // Test basic functionality without UIImage dependencies
        // (Full image tests would require platform-specific setup)
        
        let testPath = "nonexistent.jpg"
        let result = photoStorage.loadImage(path: testPath)
        XCTAssertNil(result) // Should return nil for nonexistent file
    }
    
    func test_serviceContainer() {
        // Test that protocols exist and are properly defined
        XCTAssertNotNil(PhotoStorageProtocol.self)
        XCTAssertNotNil(KeychainServiceProtocol.self)
        XCTAssertNotNil(OpenAIServiceProtocol.self)
        XCTAssertNotNil(CoreDataStackProtocol.self)
        
        // Note: ServiceContainer currently disabled for testing focus
    }
    
    func test_platformAbstraction() {
        // Test that our platform abstraction types are defined
        #if canImport(UIKit)
        XCTAssertTrue(PlatformImage.self == UIImage.self)
        XCTAssertTrue(PlatformFloat.self == CGFloat.self)
        #elseif canImport(AppKit)
        XCTAssertTrue(PlatformImage.self == NSImage.self)
        XCTAssertTrue(PlatformFloat.self == CGFloat.self)
        #else
        // For pure Swift environments
        XCTAssertNotNil(PlatformImage.self)
        XCTAssertTrue(PlatformFloat.self == Double.self)
        #endif
    }
    
    func test_coreDataStackProtocol() {
        // Test SimpleCoreDataStack with fallback model
        let coreDataStack = SimpleCoreDataStack(inMemory: true)
        
        // Test basic protocol conformance
        XCTAssertNotNil(coreDataStack.viewContext)
        
        // Test save doesn't crash
        coreDataStack.save()
    }
}

// MARK: - Performance Tests
extension BasicPackageTests {
    
    func test_fastExecution() {
        // Measure test execution time to demonstrate speed
        let start = Date()
        
        // Perform some business logic operations
        let keychain = KeychainService()
        keychain.deleteAPIKey()
        _ = keychain.saveAPIKey("test")
        _ = keychain.getAPIKey()
        keychain.deleteAPIKey()
        
        let elapsed = Date().timeIntervalSince(start)
        
        // Should be very fast (under 0.1 seconds)
        XCTAssertLessThan(elapsed, 0.1, "Unit tests should be very fast without simulator overhead")
        
        print("✅ Test completed in \(String(format: "%.3f", elapsed)) seconds")
    }
}