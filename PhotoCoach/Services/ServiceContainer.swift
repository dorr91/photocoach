import Foundation

// ServiceContainer manages all service dependencies for the app
class ServiceContainer: ObservableObject {
    let keychainService: KeychainServiceProtocol
    let photoStorage: PhotoStorageProtocol
    let coreDataStack: CoreDataStackProtocol
    let openAIService: OpenAIServiceType
    
    init(inMemory: Bool = false) {
        self.keychainService = KeychainService()
        self.photoStorage = PhotoStorageService()
        self.coreDataStack = CoreDataStack(inMemory: inMemory, photoStorage: photoStorage)
        
        let openAI = OpenAIService(
            urlSession: URLSession.shared,
            keychainService: keychainService
        )
        self.openAIService = OpenAIServiceWrapper(service: openAI)
    }
    
    // Test initializer
    init(keychainService: KeychainServiceProtocol,
         photoStorage: PhotoStorageProtocol,
         coreDataStack: CoreDataStackProtocol,
         openAIService: OpenAIServiceType) {
        self.keychainService = keychainService
        self.photoStorage = photoStorage
        self.coreDataStack = coreDataStack
        self.openAIService = openAIService
    }
}