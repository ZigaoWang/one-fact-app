import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = FactViewModel()
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        HomeView()
            .environmentObject(viewModel)
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    viewModel.checkDailyFactStatus()
                }
            }
    }
}

#Preview {
    ContentView()
}
