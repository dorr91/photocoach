import XCTest
import Foundation

// Import our mocks (but not PhotoCoach app)
@testable import PhotoCoachTests

// Isolated unit tests that don't depend on PhotoCoach app
final class IsolatedMockTests: XCTestCase {
    
    func test_mockOpenAIService_initialization() {
        let mock = MockOpenAIService()
        XCTAssertEqual(mock.streamFeedbackCallCount, 0)
        XCTAssertEqual(mock.clearSessionCallCount, 0)
    }
    
    func test_mockOpenAIService_streamFeedback() async {
        let mock = MockOpenAIService()
        mock.mockStreamResponses = ["Hello", "World"]
        
        let testData = Data("test".utf8)
        let stream = await mock.streamFeedback(imageData: testData)
        
        var results: [String] = []
        do {
            for try await chunk in stream {
                results.append(chunk)
            }
        } catch {
            XCTFail("Stream should not throw: \(error)")
        }
        
        XCTAssertEqual(results, ["Hello", "World"])
        XCTAssertEqual(mock.streamFeedbackCallCount, 1)
        XCTAssertEqual(mock.lastImageData, testData)
    }
    
    func test_mockOpenAIService_clearSession() async {
        let mock = MockOpenAIService()
        
        await mock.clearSession()
        
        XCTAssertEqual(mock.clearSessionCallCount, 1)
    }
    
    func test_mockOpenAIService_reset() {
        let mock = MockOpenAIService()
        mock.mockStreamResponses = ["test"]
        mock.streamFeedbackCallCount = 5
        mock.clearSessionCallCount = 3
        
        mock.reset()
        
        XCTAssertEqual(mock.mockStreamResponses.count, 0)
        XCTAssertEqual(mock.streamFeedbackCallCount, 0)
        XCTAssertEqual(mock.clearSessionCallCount, 0)
        XCTAssertNil(mock.lastImageData)
    }
    
    func test_mockKeychainService_apiKey() {
        let mock = MockKeychainService()
        
        XCTAssertNil(mock.getAPIKey())
        
        mock.setPresetAPIKey("test-key")
        XCTAssertEqual(mock.getAPIKey(), "test-key")
        
        mock.deleteAPIKey()
        XCTAssertNil(mock.getAPIKey())
    }
}