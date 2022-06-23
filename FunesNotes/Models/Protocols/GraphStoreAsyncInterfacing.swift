import Foundation
import UrsusHTTP
import SwiftGraphStore

protocol GraphStoreAsyncInterfacing {
    var graphStoreConnection: GraphStoreConnecting { get }

    func login() async throws -> Ship
    func connect() async throws
    func startSubscription() async throws
    
    func readRootNodes(resource: Resource) async throws -> GraphStoreUpdate
    func readNode(resource: Resource, index: Index, mode: ScryMode) async throws -> GraphStoreUpdate
    func readChildren(resource: Resource, index: Index, mode: ScryMode) async throws -> GraphStoreUpdate
    
    func createGraph(resource: Resource) async throws
    func addNode(resource: Resource, post: Post, children: Graph?) async throws
}
