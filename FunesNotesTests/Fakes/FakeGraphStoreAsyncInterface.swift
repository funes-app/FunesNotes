import Foundation
import UrsusHTTP
import SwiftGraphStore
@testable import FunesNotes
import SwiftGraphStoreFakes

class FakeGraphStoreAsyncInterface: GraphStoreAsyncInterfacing {
    var graphStoreConnection: GraphStoreConnecting = FakeGraphStoreConnection()
    
    var login_calledCount = 0
    var login_error: Error?
    var login_returnShip = Ship.testInstance
    func login() async throws -> Ship {
        login_calledCount += 1
        
        if let error = login_error {
            throw error
        } else {
            return login_returnShip
        }
    }
    
    var connect_calledCount = 0
    var connect_error: Error?
    func connect() async throws {
        connect_calledCount += 1
        
        if let error = connect_error {
            throw error
        }
    }
    
    var startSubscription_calledCount = 0
    var startSubscription_error: Error?
    func startSubscription() async throws {
        startSubscription_calledCount += 1
        
        if let error = startSubscription_error {
            throw error
        }
    }
    
    var readRootNodes_calledCount = 0
    var readRootNodes_paramResource: Resource?
    var readRootNodes_error: Error?
    var readRootNodes_returnUpdate: GraphStoreUpdate?
    func readRootNodes(resource: Resource) async throws -> GraphStoreUpdate {
        readRootNodes_calledCount += 1
        readRootNodes_paramResource = resource
        
        if let error = readRootNodes_error {
            throw error
        } else {
            return readRootNodes_returnUpdate!
        }
    }
    
    var readNode_calledCount = 0
    var readNode_paramResource: Resource?
    var readNode_paramIndex: Index?
    var readNode_paramMode: ScryMode?
    var readNode_error: ScryError?
    var readNode_returnUpdate: GraphStoreUpdate?
    func readNode(resource: Resource, index: Index, mode: ScryMode) async throws -> GraphStoreUpdate {
        readNode_calledCount += 1
        readNode_paramResource = resource
        readNode_paramIndex = index
        readNode_paramMode = mode
        
        if let error = readNode_error {
            throw error
        } else {
            return readNode_returnUpdate!
        }
    }
    
    var readChildren_calledCount = 0
    var readChildren_paramResource: Resource?
    var readChildren_paramIndex: Index?
    var readChildren_paramMode: ScryMode?
    var readChildren_error: ScryError?
    var readChildren_returnUpdate: GraphStoreUpdate?
    func readChildren(resource: Resource, index: Index, mode: ScryMode) async throws -> GraphStoreUpdate {
        readChildren_calledCount += 1
        readChildren_paramResource = resource
        readChildren_paramIndex = index
        readChildren_paramMode = mode
        
        if let error = readChildren_error {
            throw error
        } else {
            return readChildren_returnUpdate!
        }
    }

    var createGraph_calledCount = 0
    var createGraph_paramResource: Resource?
    var createGraph_error: PokeError?
    func createGraph(resource: Resource) async throws {
        createGraph_calledCount += 1
        createGraph_paramResource = resource
        
        if let error = createGraph_error {
            throw error
        }
    }
    
    var addNode_calledCount = 0
    var addNode_paramResource: Resource?
    var addNode_paramPost: Post?
    var addNode_paramChildren: Graph?
    var addNode_error: PokeError?
    func addNode(resource: Resource, post: Post, children: Graph?) async throws {
        addNode_calledCount += 1
        addNode_paramResource = resource
        addNode_paramPost = post
        addNode_paramChildren = children
        
        if let error = addNode_error {
            throw error
        }
    }
}
