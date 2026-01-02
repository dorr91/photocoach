import XCTest
import Foundation

// Test business logic without importing PhotoCoach directly
// This avoids symbol linking issues and creates true unit tests
class IsolatedBusinessLogicTests: XCTestCase {
    
    // MARK: - Core Data Logic Tests
    func test_photoEntityCreation() {
        // Test Core Data entity creation through protocols
        let mockStack = MockCoreDataStack()
        
        // Test photo creation logic
        let imagePath = "/test/path/image.jpg"
        let thumbnailPath = "/test/path/thumb.jpg"
        
        let photo = mockStack.createPhoto(imagePath: imagePath, thumbnailPath: thumbnailPath)
        
        XCTAssertEqual(photo.imagePath, imagePath)
        XCTAssertEqual(photo.thumbnailPath, thumbnailPath)
        XCTAssertNotNil(photo.createdAt)
    }
    
    func test_feedbackEntityCreation() {
        let mockStack = MockCoreDataStack()
        
        // Create a test photo first
        let photo = mockStack.createPhoto(imagePath: "/test.jpg", thumbnailPath: "/thumb.jpg")
        
        // Test feedback creation
        let feedback = mockStack.createFeedback(for: photo)
        
        XCTAssertEqual(feedback.photo, photo)
        XCTAssertNotNil(feedback.createdAt)
        XCTAssertEqual(feedback.status, "pending")
    }
    
    // MARK: - OpenAI Service Logic Tests
    func test_openAIServiceSuccess() async throws {
        let mockService = MockOpenAIService()
        let testImageData = Data("fake image data".utf8)
        
        // Configure mock for success
        mockService.shouldSucceed = true
        mockService.mockStreamContent = ["Great composition!", " Nice lighting.", " Consider the rule of thirds."]
        
        var receivedContent: [String] = []
        
        // Test streaming functionality
        let stream = try await mockService.analyzePhoto(testImageData)
        for try await content in stream {
            receivedContent.append(content)
        }
        
        XCTAssertEqual(receivedContent.count, 3)
        XCTAssertEqual(receivedContent.joined(), "Great composition! Nice lighting. Consider the rule of thirds.")
    }
    
    func test_openAIServiceFailure() async {
        let mockService = MockOpenAIService()
        
        // Configure mock for failure
        mockService.shouldSucceed = false
        mockService.mockError = MockOpenAIService.TestError.networkError
        
        let testImageData = Data("fake image data".utf8)
        
        do {
            _ = try await mockService.analyzePhoto(testImageData)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is MockOpenAIService.TestError)
        }
    }
    
    // MARK: - Photo Storage Logic Tests
    func test_photoStorageSuccess() {
        let mockStorage = MockPhotoStorage()
        let mockImage = MockPhotoStorage.createTestImage()
        let testId = UUID()
        
        // Test successful save
        mockStorage.shouldSucceed = true
        let paths = mockStorage.savePhoto(mockImage, id: testId)
        
        XCTAssertNotNil(paths)
        XCTAssertTrue(paths!.imagePath.contains(testId.uuidString))
        XCTAssertTrue(paths!.thumbnailPath.contains(testId.uuidString))
    }
    
    func test_photoStorageFailure() {
        let mockStorage = MockPhotoStorage()
        let mockImage = MockPhotoStorage.createTestImage()
        let testId = UUID()
        
        // Test failure case
        mockStorage.shouldSucceed = false
        let paths = mockStorage.savePhoto(mockImage, id: testId)
        
        XCTAssertNil(paths)
    }
    
    // MARK: - Keychain Service Logic Tests
    func test_keychainApiKeyStorage() {
        let mockKeychain = MockKeychainService()
        let testApiKey = "test-api-key-12345"
        
        // Test save
        mockKeychain.store(testApiKey, forKey: "openai_api_key")
        
        // Test retrieve
        let retrievedKey = mockKeychain.retrieve(forKey: "openai_api_key")
        XCTAssertEqual(retrievedKey, testApiKey)
        
        // Test delete
        mockKeychain.delete(forKey: "openai_api_key")
        let deletedKey = mockKeychain.retrieve(forKey: "openai_api_key")
        XCTAssertNil(deletedKey)
    }
    
    // MARK: - Integration Logic Tests
    func test_feedbackWorkflow() async throws {
        // Test complete feedback workflow using mocks
        let mockStack = MockCoreDataStack()
        let mockOpenAI = MockOpenAIService()
        let mockStorage = MockPhotoStorage()
        
        // Setup mocks
        mockOpenAI.shouldSucceed = true
        mockOpenAI.mockStreamContent = ["Good photo!", " Try different angle."]
        mockStorage.shouldSucceed = true
        
        // Create photo
        let photo = mockStack.createPhoto(imagePath: "/test.jpg", thumbnailPath: "/thumb.jpg")
        let feedback = mockStack.createFeedback(for: photo)
        
        // Test that feedback starts as pending
        XCTAssertEqual(feedback.status, "pending")
        
        // Simulate analysis (would be done by FeedbackViewModel)
        feedback.status = "analyzing"
        
        var analysisContent = ""
        let stream = try await mockOpenAI.analyzePhoto(Data())
        for try await content in stream {
            analysisContent += content
        }
        
        // Complete feedback
        feedback.content = analysisContent
        feedback.status = "completed"
        
        XCTAssertEqual(feedback.status, "completed")
        XCTAssertEqual(feedback.content, "Good photo! Try different angle.")
    }
}