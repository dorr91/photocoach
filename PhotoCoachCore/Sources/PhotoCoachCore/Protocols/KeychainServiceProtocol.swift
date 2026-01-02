import Foundation

public protocol KeychainServiceProtocol {
    func saveAPIKey(_ key: String) -> Bool
    func getAPIKey() -> String?
    func deleteAPIKey() -> Bool
    func hasAPIKey() -> Bool
}