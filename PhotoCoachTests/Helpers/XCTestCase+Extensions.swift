import XCTest
import Foundation
@testable import PhotoCoach

extension XCTestCase {
    /// Creates a temporary directory for test files
    func createTemporaryDirectory() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let testDir = tempDir.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)
        return testDir
    }
    
    /// Removes a directory and all its contents
    func removeDirectory(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
    
    /// Asserts that two arrays contain the same elements (order independent)
    func assertArraysContainSameElements<T: Equatable & Hashable>(
        _ array1: [T],
        _ array2: [T],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(Set(array1), Set(array2), file: file, line: line)
    }
    
    /// Asserts that a condition becomes true within a timeout
    func assertEventually(
        timeout: TimeInterval = 1.0,
        description: String = "Condition",
        file: StaticString = #filePath,
        line: UInt = #line,
        condition: @escaping () -> Bool
    ) {
        let expectation = XCTestExpectation(description: description)
        
        let startTime = Date()
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if condition() {
                expectation.fulfill()
                timer.invalidate()
            } else if Date().timeIntervalSince(startTime) > timeout {
                timer.invalidate()
                XCTFail("Timeout waiting for \(description)", file: file, line: line)
            }
        }
        
        wait(for: [expectation], timeout: timeout + 1.0)
    }
    
    /// Asserts that an async throwing operation completes without throwing
    func assertNoThrow<T>(
        file: StaticString = #filePath,
        line: UInt = #line,
        _ operation: () async throws -> T
    ) async -> T? {
        do {
            return try await operation()
        } catch {
            XCTFail("Unexpected error: \(error)", file: file, line: line)
            return nil
        }
    }
    
    /// Asserts that an async operation throws a specific error
    func assertThrows<T, E: Error & Equatable>(
        _ expectedError: E,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ operation: () async throws -> T
    ) async {
        do {
            _ = try await operation()
            XCTFail("Expected error \(expectedError) but operation succeeded", file: file, line: line)
        } catch let error as E {
            XCTAssertEqual(error, expectedError, file: file, line: line)
        } catch {
            XCTFail("Expected error \(expectedError) but got \(error)", file: file, line: line)
        }
    }
    
    /// Asserts that an async operation throws any error
    func assertThrowsAnyError<T>(
        file: StaticString = #filePath,
        line: UInt = #line,
        _ operation: () async throws -> T
    ) async {
        do {
            _ = try await operation()
            XCTFail("Expected operation to throw an error but it succeeded", file: file, line: line)
        } catch {
            // Expected - any error is fine
        }
    }
    
    /// Creates a test UUID with a specific string for easier identification
    func testUUID(suffix: String = "test") -> UUID {
        return UUID(uuidString: "00000000-0000-0000-0000-\(suffix.padding(toLength: 12, withPad: "0", startingAt: 0))") 
            ?? UUID()
    }
    
    /// Creates a test date relative to now
    func testDate(daysFromNow: Int = 0, hoursFromNow: Int = 0) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        guard let result = calendar.date(byAdding: .day, value: daysFromNow, to: now),
              let finalResult = calendar.date(byAdding: .hour, value: hoursFromNow, to: result) else {
            return now
        }
        
        return finalResult
    }
}

// MARK: - Performance Testing

extension XCTestCase {
    /// Measures the performance of an async operation
    func measureAsync(
        name: String = #function,
        _ operation: @escaping () async throws -> Void
    ) {
        measure {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                try? await operation()
                semaphore.signal()
            }
            semaphore.wait()
        }
    }
    
    /// Measures time taken for an async operation
    func timeAsync(
        _ operation: @escaping () async throws -> Void
    ) async -> TimeInterval {
        let startTime = Date()
        try? await operation()
        return Date().timeIntervalSince(startTime)
    }
}

// MARK: - Mock Assertion Helpers

extension XCTestCase {
    /// Asserts that a mock was called a specific number of times
    func assertCallCount(
        _ actualCount: Int,
        equals expectedCount: Int,
        for operation: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(actualCount, expectedCount, "\(operation) should have been called \(expectedCount) times but was called \(actualCount) times", file: file, line: line)
    }
    
    /// Asserts that a mock was called at least once
    func assertCalled(
        _ callCount: Int,
        for operation: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertGreaterThan(callCount, 0, "\(operation) should have been called at least once", file: file, line: line)
    }
    
    /// Asserts that a mock was never called
    func assertNotCalled(
        _ callCount: Int,
        for operation: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(callCount, 0, "\(operation) should not have been called", file: file, line: line)
    }
}