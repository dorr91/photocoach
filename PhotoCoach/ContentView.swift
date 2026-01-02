import SwiftUI

struct ContentView: View {
    @EnvironmentObject var container: ServiceContainer
    @EnvironmentObject var coreData: CoreDataStack
    @State private var navigateToReview = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            CameraView(navigateToReview: $navigateToReview, showSettings: $showSettings)
                .navigationDestination(isPresented: $navigateToReview) {
                    PhotoReviewView()
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                }
        }
    }
}

#Preview {
    let container = ServiceContainer(inMemory: true)
    return ContentView()
        .environmentObject(container)
        .environmentObject(container.coreDataStack as! CoreDataStack)
}
