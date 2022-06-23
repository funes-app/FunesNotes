import Foundation
import Combine
import UrsusAtom
import UrsusHTTP

class PreviewShipSession: ShipSessioning {
    private let timeoutTime: UInt64 = 2 * 1_000_000_000
    var ship: Ship?
    
    var noteGraphConnector: NoteGraphConnecting?

    @Published var connectionError: ConnectionError?
    var connectionErrorReceived: AnyPublisher<ConnectionError, Never> {
        $connectionError
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    @Published var connectionStatus = ConnectionStatus.notLoggedIn
    var connectionStatusChanged: AnyPublisher<ConnectionStatus, Never> {
        $connectionStatus
            .eraseToAnyPublisher()
    }
    
    func setupGraphStoreConnection(url: URL, code: PatP) {
        connectionStatus = .readyToConnect
    }
    
    func openConnection() async {
        connectionStatus = .loggingIn
        try? await Task.sleep(nanoseconds: timeoutTime)
        
        connectionStatus = .openingAirlock
        try? await Task.sleep(nanoseconds: timeoutTime)
        
        connectionStatus = .subscribing
        try? await Task.sleep(nanoseconds: timeoutTime)
                
        connectionStatus = .connected(ship: Ship.random)
    }
    
    func logout() {
        Task {
            try? await Task.sleep(nanoseconds: timeoutTime)
            self.connectionStatus = .notLoggedIn
        }
    }
    
    func downloadLatestNoteRevision(id: NoteId) async throws -> NoteContents {
        throw NSError(domain: "", code: 0)
    }
    
    func downloadLatestNoteMetaRevision(id: NoteId) async throws -> NoteMeta {
        throw NSError(domain: "", code: 0)
    }
    
    func createGraphStoreNote(note: NoteContents, noteMeta: NoteMeta) async {
    }
    
    func createGraphStoreRevisions(note: NoteContents, noteMeta: NoteMeta) async {
    }
}
