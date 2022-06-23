import SwiftUI

struct ContentView: View {
    let fileConnector: FileConnector
    let shipSession: ShipSessioning
    @ObservedObject var appViewModel: AppViewModel
    
    var loggedIn = false
    
    var noteListViewModel: NoteListViewModel {
        NoteListViewModel(appViewModel: appViewModel)
    }
    
    init(fileConnector: FileConnector,
         shipSession: ShipSessioning) {
        self.fileConnector = fileConnector
        self.shipSession = shipSession
        self.appViewModel = AppViewModel(fileConnector: fileConnector,
                                         shipSession: shipSession)
    }
    
    var body: some View {
        Group {
            if case .notLoggedIn = appViewModel.appSetupStatus {
                LoginView(appViewModel: appViewModel)
            } else if case .setupComplete = appViewModel.appSetupStatus {
                NoteListView(viewModel: noteListViewModel)
            } else {
                ConnectingView(appViewModel: appViewModel)
            }
        }
        .alert(isPresented: self.$appViewModel.showFileError,
               error: self.appViewModel.fileError,
               actions: {})
        .alert(isPresented: self.$appViewModel.showGraphError,
               error: self.appViewModel.graphError,
               actions: {})
        .alert(isPresented: self.$appViewModel.showConnectionError,
               error: self.appViewModel.connectionError,
               actions: {})
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(fileConnector: FileConnector(),
                    shipSession: PreviewShipSession())
    }
}
