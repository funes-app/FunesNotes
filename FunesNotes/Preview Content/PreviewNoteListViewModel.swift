import Foundation
import UrsusHTTP

extension NoteListViewModel {
    static func makePreviewVM(activityStatus: SynchronizerActivityStatus = .idle) -> NoteListViewModel {
        let fileConnector = FileConnector()
        let session = PreviewShipSession()
        session.ship = Ship.random
        
        let graphStoreSync = PreviewGraphStoreSync()
        graphStoreSync._activityChanged = activityStatus
        
        let appViewModel = AppViewModel(fileConnector: fileConnector,
                                        shipSession: session)
        appViewModel.graphStoreSync = graphStoreSync
        
        return NoteListViewModel(appViewModel: appViewModel)        
    }
}
