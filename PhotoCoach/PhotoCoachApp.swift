import SwiftUI

@main
struct PhotoCoachApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var coreData = CoreDataStack.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coreData)
        }
    }
}
