import Foundation
@testable import PhotoCoach

class MockURLSession: URLSessionProtocol {
    private var mockData: Data = Data()
    private var mockResponse: URLResponse?
    private var mockError: Error?
    
    var bytesCallCount = 0
    var lastRequest: URLRequest?
    
    func bytes(for request: URLRequest) async throws -> (URLSession.AsyncBytes, URLResponse) {
        bytesCallCount += 1
        lastRequest = request
        
        if let error = mockError {
            throw error
        }
        
        let response = mockResponse ?? HTTPURLResponse(
            url: request.url ?? URL(string: "https://test.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        // Create a URLSession to get real AsyncBytes with our mock data
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try mockData.write(to: tempURL)
        
        let fileURL = tempURL
        let fileURLRequest = URLRequest(url: fileURL)
        
        let (asyncBytes, _) = try await URLSession.shared.bytes(for: fileURLRequest)
        
        // Clean up temp file
        try? FileManager.default.removeItem(at: tempURL)
        
        return (asyncBytes, response)
    }
    
    // Test helper methods
    func setMockResponse(data: Data, response: URLResponse? = nil) {
        mockData = data
        mockResponse = response
    }
    
    func setMockError(_ error: Error) {
        mockError = error
    }
    
    func reset() {
        mockData = Data()
        mockResponse = nil
        mockError = nil
        bytesCallCount = 0
        lastRequest = nil
    }
}