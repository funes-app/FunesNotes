import Foundation
import Combine
import UrsusAtom
import UrsusHTTP

protocol ShipSessioning {
    var ship: Ship? { get }
    var noteGraphConnector: NoteGraphConnecting? { get }
    
    var connectionErrorReceived: AnyPublisher<ConnectionError, Never> { get }
    var connectionStatusChanged: AnyPublisher<ConnectionStatus, Never> { get }
    
    func setupGraphStoreConnection(url: URL, code: PatP)
    func openConnection() async
    
    func logout()
}
