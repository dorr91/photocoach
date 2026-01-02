import Foundation

protocol URLSessionProtocol: Sendable {
    func bytes(for request: URLRequest) async throws -> (URLSession.AsyncBytes, URLResponse)
}

extension URLSession: URLSessionProtocol {
    func bytes(for request: URLRequest) async throws -> (URLSession.AsyncBytes, URLResponse) {
        // Call the delegate-accepting version with nil to avoid recursion
        try await self.bytes(for: request, delegate: nil)
    }
}