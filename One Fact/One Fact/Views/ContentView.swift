import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = FactViewModel()
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        AsyncHomeView()
            .environmentObject(viewModel)
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    viewModel.checkDailyFactStatus()
                }
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
