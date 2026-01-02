import Foundation
@testable import PhotoCoach

class MockFileManager: FileManagerProtocol {
    private var mockDirectories: [URL] = []
    private var existingPaths: Set<String> = []
    private var directoryContents: [URL: [URL]] = [:]
    
    var urlsCallCount = 0
    var fileExistsCallCount = 0
    var createDirectoryCallCount = 0
    var removeItemCallCount = 0
    var contentsOfDirectoryCallCount = 0
    
    var shouldThrowOnCreateDirectory = false
    var shouldThrowOnRemoveItem = false
    var shouldThrowOnContentsOfDirectory = false
    
    var createDirectoryError: Error = NSError(domain: "MockFileManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock create directory error"])
    var removeItemError: Error = NSError(domain: "MockFileManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Mock remove item error"])
    var contentsError: Error = NSError(domain: "MockFileManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Mock contents error"])
    
    func urls(for directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL] {
        urlsCallCount += 1
        return mockDirectories
    }
    
    func fileExists(atPath path: String) -> Bool {
        fileExistsCallCount += 1
        return existingPaths.contains(path)
    }
    
    func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey : Any]?) throws {
        createDirectoryCallCount += 1
        
        if shouldThrowOnCreateDirectory {
            throw createDirectoryError
        }
        
        existingPaths.insert(url.path)
    }
    
    func removeItem(at url: URL) throws {
        removeItemCallCount += 1
        
        if shouldThrowOnRemoveItem {
            throw removeItemError
        }
        
        existingPaths.remove(url.path)
        directoryContents.removeValue(forKey: url)
    }
    
    func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions) throws -> [URL] {
        contentsOfDirectoryCallCount += 1
        
        if shouldThrowOnContentsOfDirectory {
            throw contentsError
        }
        
        return directoryContents[url] ?? []
    }
    
    // Test helper methods
    func reset() {
        mockDirectories.removeAll()
        existingPaths.removeAll()
        directoryContents.removeAll()
        urlsCallCount = 0
        fileExistsCallCount = 0
        createDirectoryCallCount = 0
        removeItemCallCount = 0
        contentsOfDirectoryCallCount = 0
        shouldThrowOnCreateDirectory = false
        shouldThrowOnRemoveItem = false
        shouldThrowOnContentsOfDirectory = false
    }
    
    func setMockDirectories(_ directories: [URL]) {
        mockDirectories = directories
    }
    
    func addExistingPath(_ path: String) {
        existingPaths.insert(path)
    }
    
    func setDirectoryContents(_ url: URL, contents: [URL]) {
        directoryContents[url] = contents
    }
}