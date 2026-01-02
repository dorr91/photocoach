import SwiftUI

@main
struct PhotoCoachApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var container = ServiceContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(container)
                .environmentObject(container.coreDataStack as! CoreDataStack)
        }
    }
}
