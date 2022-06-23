import Foundation

protocol AppViewModeling {
    var fileConnector: FileConnecting { get }
    var shipSession: ShipSessioning { get }
    var graphStoreSync: GraphStoreSyncing? { get }
    
    func logout() async
}
