import Foundation

public protocol URLSessionProtocol {
    func bytes(for request: URLRequest) async throws -> (URLSession.AsyncBytes, URLResponse)
}

extension URLSession: URLSessionProtocol {
    // URLSession.bytes returns exactly the type we need
    public func bytes(for request: URLRequest) async throws -> (URLSession.AsyncBytes, URLResponse) {
        return try await bytes(for: request, delegate: nil)
    }
}