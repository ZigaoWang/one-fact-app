import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: FactViewModel
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        AsyncHomeView()
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
            .environmentObject(FactViewModel())
    }
}
