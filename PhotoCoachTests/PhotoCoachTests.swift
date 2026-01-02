//
//  PhotoCoachTests.swift
//  PhotoCoachTests
//
//  Created by David Orr on 12/14/25.
//

import XCTest
@testable import PhotoCoach

/// Main test suite entry point
/// Individual test classes are organized in the Tests/ directory
final class PhotoCoachTests: XCTestCase {
    
    func testTestInfrastructure() {
        // Verify test infrastructure is working
        let mockService = MockOpenAIService()
        XCTAssertEqual(mockService.streamFeedbackCallCount, 0)
        
        let mockStorage = MockPhotoStorage()
        XCTAssertEqual(mockStorage.storedImageCount, 0)
        
        let mockKeychain = MockKeychainService()
        XCTAssertFalse(mockKeychain.hasAPIKey())
        
        let mockCoreData = MockCoreDataStack()
        XCTAssertEqual(mockCoreData.photoCount, 0)
    }
}
