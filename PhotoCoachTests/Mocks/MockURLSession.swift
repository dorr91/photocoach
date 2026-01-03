import Foundation
@testable import PhotoCoach

class MockURLSession: URLSessionProtocol {
    private var mockData: Data = Data()
    private var mockResponse: URLResponse?
    private var mockError: Error?
    private var tempFiles: [URL] = []

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
        tempFiles.append(tempURL)

        let fileURLRequest = URLRequest(url: tempURL)

        let (asyncBytes, _) = try await URLSession.shared.bytes(for: fileURLRequest)

        // Don't delete temp file here - it's still being read by the stream
        // Files will be cleaned up in reset() or deinit

        return (asyncBytes, response)
    }

    deinit {
        cleanupTempFiles()
    }

    private func cleanupTempFiles() {
        for url in tempFiles {
            try? FileManager.default.removeItem(at: url)
        }
        tempFiles.removeAll()
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
        cleanupTempFiles()
        mockData = Data()
        mockResponse = nil
        mockError = nil
        bytesCallCount = 0
        lastRequest = nil
    }
}