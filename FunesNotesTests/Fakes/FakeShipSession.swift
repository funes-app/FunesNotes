import Foundation
import Combine
import UrsusAtom
import UrsusHTTP
@testable import FunesNotes

class FakeShipSession: ShipSessioning {
    var ship: Ship?
    var noteGraphConnector: NoteGraphConnecting?

    @Published var connectionError: ConnectionError?
    var connectionErrorReceived: AnyPublisher<ConnectionError, Never> {
        $connectionError
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    @Published var connectionStatus: ConnectionStatus
    var connectionStatusChanged: AnyPublisher<ConnectionStatus, Never> {
        $connectionStatus
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    init(connectionStatus: ConnectionStatus = .notLoggedIn) {
        self.connectionStatus = connectionStatus
    }
    
    var setupGraphStoreConnection_calledCount = 0
    var setupGraphStoreConnection_paramURL: URL?
    var setupGraphStoreConnection_paramCode: PatP?
    func setupGraphStoreConnection(url: URL, code: PatP) {
        setupGraphStoreConnection_calledCount += 1
        setupGraphStoreConnection_paramURL = url
        setupGraphStoreConnection_paramCode = code
    }
    
    var openConnection_calledCount = 0
    func openConnection() async {
        openConnection_calledCount += 1
    }
   
    var logout_calledCount = 0
    func logout() {
        logout_calledCount += 1
    }
}
