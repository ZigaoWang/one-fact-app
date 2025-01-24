import SwiftUI

@main
struct OneFactApp: App {
    @StateObject private var factViewModel = FactViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(factViewModel)
        }
    }
}
