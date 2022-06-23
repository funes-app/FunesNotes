import Foundation
@testable import FunesNotes

class FakeAppViewModel: AppViewModeling {
    var fileConnector: FileConnecting = FakeFileConnector()
    
    var shipSession: ShipSessioning = FakeShipSession()
    
    var graphStoreSync: GraphStoreSyncing? = FakeGraphStoreSync()
    
    var logout_calledCount = 0
    func logout() async {
        logout_calledCount += 1
    }
}
