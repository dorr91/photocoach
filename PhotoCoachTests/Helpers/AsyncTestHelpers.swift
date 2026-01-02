import XCTest
import Foundation

extension XCTestCase {
    /// Waits for an async stream to complete and collects all values
    func collectStream<T>(_ stream: AsyncThrowingStream<T, Error>, timeout: TimeInterval = 5.0) async throws -> [T] {
        var results: [T] = []
        let startTime = Date()
        
        for try await value in stream {
            results.append(value)
            
            // Timeout protection
            if Date().timeIntervalSince(startTime) > timeout {
                XCTFail("Stream collection timed out after \(timeout) seconds")
                break
            }
        }
        
        return results
    }
    
    /// Waits for a condition to be true within a timeout
    func waitForCondition(
        timeout: TimeInterval = 5.0,
        pollInterval: TimeInterval = 0.1,
        description: String = "Condition to be met",
        condition: @escaping () async -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        
        while Date() < deadline {
            if await condition() {
                return
            }
            try await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }
        
        XCTFail("Timeout waiting for \(description) after \(timeout) seconds")
    }
    
    /// Waits for an async operation to complete with a timeout
    func withTimeout<T>(
        _ timeout: TimeInterval = 5.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw TimeoutError(timeout: timeout)
            }
            
            guard let result = try await group.next() else {
                throw TimeoutError(timeout: timeout)
            }
            
            group.cancelAll()
            return result
        }
    }
    
    /// Creates a test expectation that can be fulfilled multiple times
    func multiExpectation(description: String, expectedFulfillmentCount: Int = 1) -> XCTestExpectation {
        let expectation = self.expectation(description: description)
        expectation.expectedFulfillmentCount = expectedFulfillmentCount
        return expectation
    }
    
    /// Waits for multiple async operations to complete
    func waitForAll<T>(
        _ operations: [() async throws -> T],
        timeout: TimeInterval = 5.0
    ) async throws -> [T] {
        try await withThrowingTaskGroup(of: (Int, T).self) { group in
            for (index, operation) in operations.enumerated() {
                group.addTask {
                    let result = try await operation()
                    return (index, result)
                }
            }
            
            var results: [T?] = Array(repeating: nil, count: operations.count)
            
            for try await (index, result) in group {
                results[index] = result
            }
            
            return results.compactMap { $0 }
        }
    }
}

struct TimeoutError: Error, LocalizedError {
    let timeout: TimeInterval
    
    var errorDescription: String? {
        "Operation timed out after \(timeout) seconds"
    }
}

// MARK: - Stream Testing Utilities

/// Utility for testing streaming operations
class StreamTester<T> {
    private var values: [T] = []
    private var error: Error?
    private var isComplete = false
    
    func collect(from stream: AsyncThrowingStream<T, Error>) async {
        do {
            for try await value in stream {
                values.append(value)
            }
            isComplete = true
        } catch {
            self.error = error
            isComplete = true
        }
    }
    
    var collectedValues: [T] { values }
    var thrownError: Error? { error }
    var hasCompleted: Bool { isComplete }
    var isEmpty: Bool { values.isEmpty }
    var count: Int { values.count }
    
    func reset() {
        values.removeAll()
        error = nil
        isComplete = false
    }
}

// MARK: - Mock Data Generation

extension Data {
    static func mockImageData(size: Int = 1024) -> Data {
        Data(repeating: 0xFF, count: size)
    }
    
    static func mockJSONData<T: Codable>(_ object: T) throws -> Data {
        try JSONEncoder().encode(object)
    }
}