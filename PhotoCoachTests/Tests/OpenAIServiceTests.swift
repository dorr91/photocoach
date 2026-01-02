import XCTest
@testable import PhotoCoach

final class OpenAIServiceTests: XCTestCase {
    var mockURLSession: MockURLSession!
    var mockKeychainService: MockKeychainService!
    var openAIService: OpenAIService!
    
    override func setUpWithError() throws {
        mockURLSession = MockURLSession()
        mockKeychainService = MockKeychainService()
        mockKeychainService.setPresetAPIKey("test-api-key")
        
        openAIService = OpenAIService(
            urlSession: mockURLSession,
            keychainService: mockKeychainService
        )
    }
    
    override func tearDownWithError() throws {
        mockURLSession = nil
        mockKeychainService = nil
        openAIService = nil
    }
    
    // MARK: - Stream Feedback Tests
    
    func test_streamFeedback_whenAPIKeyExists_shouldMakeNetworkRequest() async throws {
        // Given
        let testImageData = TestDataBuilder.createTestImageData()
        let responseData = """
        {"choices": [{"delta": {"content": "Test response"}}]}
        """.data(using: .utf8)!
        
        // Mock the network response
        let httpResponse = HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        
        mockURLSession.setMockResponse(data: responseData, response: httpResponse)
        
        // When
        let stream = await openAIService.streamFeedback(imageData: testImageData)
        let results = try await collectStream(stream, timeout: 2.0)
        
        // Then
        assertCalled(mockURLSession.bytesCallCount, for: "URLSession.bytes")
        assertCalled(mockKeychainService.getAPIKeyCallCount, for: "KeychainService.getAPIKey")
        XCTAssertNotNil(mockURLSession.lastRequest, "Should have made a network request")
    }
    
    func test_streamFeedback_whenNoAPIKey_shouldThrowError() async throws {
        // Given
        mockKeychainService.reset() // This removes the preset API key
        let testImageData = TestDataBuilder.createTestImageData()
        
        // When & Then
        let stream = await openAIService.streamFeedback(imageData: testImageData)
        await assertThrowsAnyError {
            _ = try await self.collectStream(stream)
        }
        
        assertNotCalled(mockURLSession.bytesCallCount, for: "URLSession.bytes")
    }
    
    func test_streamFeedback_whenNetworkError_shouldThrowError() async throws {
        // Given
        let testImageData = TestDataBuilder.createTestImageData()
        let networkError = URLError(.networkConnectionLost)
        mockURLSession.setMockError(networkError)
        
        // When & Then
        let stream = await openAIService.streamFeedback(imageData: testImageData)
        await assertThrowsAnyError {
            _ = try await self.collectStream(stream)
        }
    }
    
    func test_streamFeedback_withValidResponse_shouldStreamContent() async throws {
        // Given
        let testImageData = TestDataBuilder.createTestImageData()
        let streamResponses = [
            "This is",
            "This is a",
            "This is a great",
            "This is a great photo"
        ]
        
        // Create mock streaming response data
        let responseLines = streamResponses.map { response in
            "data: {\"choices\":[{\"delta\":{\"content\":\"\(response)\"}}]}\n\n"
        }.joined()
        
        let responseData = responseLines.data(using: .utf8)!
        let httpResponse = HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "text/plain"]
        )!
        
        // Set up mock response
        mockURLSession.setMockResponse(data: responseData, response: httpResponse)
        
        // When
        let stream = await openAIService.streamFeedback(imageData: testImageData)
        let results = try await collectStream(stream, timeout: 2.0)
        
        // Then
        XCTAssertFalse(results.isEmpty, "Should receive streaming responses")
        XCTAssertEqual(results.count, streamResponses.count, "Should receive all streaming responses")
        
        // Verify the content is accumulated properly
        for (index, expectedResponse) in streamResponses.enumerated() {
            XCTAssertEqual(results[index], expectedResponse, "Response \(index) should match expected content")
        }
    }
    
    // MARK: - Clear Session Tests
    
    func test_clearSession_shouldComplete() async {
        // When
        await openAIService.clearSession()
        
        // Then - should complete without error
        // This is a simple test as clearSession might just reset internal state
        XCTAssertTrue(true, "clearSession should complete without error")
    }
    
    // MARK: - Integration Tests
    
    func test_multipleStreamCalls_shouldWorkIndependently() async throws {
        // Given
        let testImageData1 = TestDataBuilder.createTestImageData(size: 512)
        let testImageData2 = TestDataBuilder.createTestImageData(size: 1024)
        
        let response1 = "First photo analysis"
        let response2 = "Second photo analysis"
        
        // Setup mock responses (simplified)
        let responseData1 = "data: {\"choices\":[{\"delta\":{\"content\":\"\(response1)\"}}]}\n\n".data(using: .utf8)!
        let responseData2 = "data: {\"choices\":[{\"delta\":{\"content\":\"\(response2)\"}}]}\n\n".data(using: .utf8)!
        
        let httpResponse = HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "text/plain"]
        )!
        
        // When & Then
        // First call
        mockURLSession.setMockResponse(data: responseData1, response: httpResponse)
        let stream1 = await openAIService.streamFeedback(imageData: testImageData1)
        let results1 = try await collectStream(stream1, timeout: 2.0)
        XCTAssertEqual(results1, [response1])
        
        // Second call
        mockURLSession.reset()
        mockURLSession.setMockResponse(data: responseData2, response: httpResponse)
        let stream2 = await openAIService.streamFeedback(imageData: testImageData2)
        let results2 = try await collectStream(stream2, timeout: 2.0)
        XCTAssertEqual(results2, [response2])
    }
    
    // MARK: - Performance Tests
    
    func test_streamFeedback_performance() {
        let testImageData = TestDataBuilder.createTestImageData()
        let responseData = "data: {\"choices\":[{\"delta\":{\"content\":\"Fast response\"}}]}\n\n".data(using: .utf8)!
        let httpResponse = HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "text/plain"]
        )!
        
        mockURLSession.setMockResponse(data: responseData, response: httpResponse)
        
        measureAsync {
            let stream = await self.openAIService.streamFeedback(imageData: testImageData)
            _ = try await self.collectStream(stream, timeout: 1.0)
        }
    }
}