import SwiftUI

@main
struct PhotoCoachApp: App {
    @StateObject private var coreData = CoreDataStack.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coreData)
        }
    }
}
