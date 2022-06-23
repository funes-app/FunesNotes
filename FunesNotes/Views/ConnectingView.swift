import SwiftUI

struct ConnectingView: View {
    @ObservedObject var appViewModel: AppViewModel
    
    var body: some View {
        Text(appViewModel.actionText)
    }
}

struct ConnectingView_Previews: PreviewProvider {
    
    static var previews: some View {
        let appViewModel = AppViewModel(fileConnector: FileConnector(),
                                        shipSession: PreviewShipSession())
        ConnectingView(appViewModel: appViewModel)
    }
}
