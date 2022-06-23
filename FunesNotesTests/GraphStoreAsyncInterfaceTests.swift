import XCTest
import UrsusHTTP
import SwiftGraphStore
import SwiftGraphStoreFakes
@testable import FunesNotes

class GraphStoreAsyncInterfaceTests: XCTestCase {
    
    func test_doesNotRetain() async throws {
        var graphStoreConnection: FakeGraphStoreConnection? = FakeGraphStoreConnection()
        graphStoreConnection?.requestLogin_response = Ship.random
        graphStoreConnection?.requestReadRootNodes_returnUpdate = GraphStoreUpdate.testInstance
        graphStoreConnection?.requestReadNode_returnUpdate = GraphStoreUpdate.testInstance
        graphStoreConnection?.requestReadChildren_returnUpdate = GraphStoreUpdate.testInstance

        var testObject: GraphStoreAsyncInterface? = GraphStoreAsyncInterface(graphStoreConnection: graphStoreConnection!)
       
        let _ = try await testObject?.login()
        try await testObject?.connect()
        try await testObject?.startSubscription()
        let _ = try await testObject?.readRootNodes(resource: Resource.testInstance)
        let _ = try await testObject?.readNode(resource: Resource.testInstance,
                                               index: Index.testInstance,
                                               mode: .includeDescendants)
        let _ = try await testObject?.readChildren(resource: Resource.testInstance,
                                                   index: Index.testInstance,
                                                   mode: .excludeDescendants)
        try await testObject?.createGraph(resource: Resource.testInstance)
        try await testObject?.addNode(resource: Resource.testInstance,
                                      post: Post.testInstance,
                                      children: nil)
    
        await Task.yield()
        
        weak var weakTestObject = testObject
        testObject = nil
        graphStoreConnection = nil
        XCTAssertNil(weakTestObject)
    }

    func test_login_callsGraphStoreConnection() async throws {
        let graphStoreConnection = FakeGraphStoreConnection()
        
        let testObject = GraphStoreAsyncInterface(graphStoreConnection: graphStoreConnection)
        
        let _ = try await testObject.login()

        XCTAssertEqual(graphStoreConnection.requestLogin_calledCount, 1)
    }
    
    func test_login_whenLoginSucceeds_returnsShipName() async throws {
        let graphStoreConnection = FakeGraphStoreConnection()

        let testObject = GraphStoreAsyncInterface(graphStoreConnection: graphStoreConnection)

        let expectedShip = Ship.random
        graphStoreConnection.requestLogin_response = expectedShip

        let ship = try await testObject.login()

        XCTAssertEqual(ship, expectedShip)
    }
    
    func test_login_whenLoginFails_throws() async throws {
        let graphStoreConnection = FakeGraphStoreConnection()

        let testObject = GraphStoreAsyncInterface(graphStoreConnection: graphStoreConnection)
        
        let expectedLoginError = LoginError.httpsRequired
        graphStoreConnection.requestLogin_error = expectedLoginError
    
        do {
            let _ = try await testObject.login()
            XCTFail("Should have thrown here")
        } catch {
            XCTAssertEqual(error.localizedDescription, expectedLoginError.localizedDescription)
        }
    }
    
    func test_connect_callsGraphStoreConnection() async throws {
        let graphStoreConnection = FakeGraphStoreConnection()
        
        let testObject = GraphStoreAsyncInterface(graphStoreConnection: graphStoreConnection)
        
        let _ = try await testObject.connect()

        XCTAssertEqual(graphStoreConnection.requestConnect_calledCount, 1)
    }

    func test_connect_whenFails_throws() async throws {
        let graphStoreConnection = FakeGraphStoreConnection()

        let testObject = GraphStoreAsyncInterface(graphStoreConnection: graphStoreConnection)
        
        let expectedConnectError = ConnectError.connectFailed(message: UUID().uuidString)
        graphStoreConnection.requestConnect_error = expectedConnectError
    
        do {
            let _ = try await testObject.connect()
            XCTFail("Should have thrown here")
        } catch {
            XCTAssertEqual(error.localizedDescription, expectedConnectError.localizedDescription)
        }
    }
    
    func test_startSubscription_callsGraphStoreConnection() async throws {
        let graphStoreConnection = FakeGraphStoreConnection()
        
        let testObject = GraphStoreAsyncInterface(graphStoreConnection: graphStoreConnection)
        
        let _ = try await testObject.startSubscription()

        XCTAssertEqual(graphStoreConnection.requestStartSubcription_calledCount, 1)
    }

    func test_startSubscription_whenFails_throws() async throws {
        let graphStoreConnection = FakeGraphStoreConnection()

        let testObject = GraphStoreAsyncInterface(graphStoreConnection: graphStoreConnection)
        
        let expectedSubscriptionError = StartSubscriptionError.startSubscriptionFailed(message: UUID().uuidString)
        graphStoreConnection.requestStartSubscription_error = expectedSubscriptionError
    
        do {
            let _ = try await testObject.startSubscription()
            XCTFail("Should have thrown here")
        } catch {
            XCTAssertEqual(error.localizedDescription, expectedSubscriptionError.localizedDescription)
        }
    }
    
    func test_readRootNodes_callsGraphStoreConnection() async throws {
        let graphStoreConnection = FakeGraphStoreConnection()
        
        let testObject = GraphStoreAsyncInterface(graphStoreConnection: graphStoreConnection)
        
        graphStoreConnection.requestReadRootNodes_returnUpdate = GraphStoreUpdate.testInstance
        
        let resource = Resource(ship: Ship.testInstance,
                                name: UUID().uuidString)
        let _ = try await testObject.readRootNodes(resource: resource)

        XCTAssertEqual(graphStoreConnection.requestReadRootNodes_calledCount, 1)
        XCTAssertEqual(graphStoreConnection.requestReadRootNodes_paramResource, resource)
    }
    
    func test_readRootNodes_whenSucceeds_returnsUpdate() async throws {
        let graphStoreConnection = FakeGraphStoreConnection()
        
        let testObject = GraphStoreAsyncInterface(graphStoreConnection: graphStoreConnection)
        
        let expectedUpdate = GraphStoreUpdate.testInstance
        graphStoreConnection.requestReadRootNodes_returnUpdate = expectedUpdate
        
        let update = try await testObject.readRootNodes(resource: Resource.testInstance)

        XCTAssertEqual(update, expectedUpdate)
    }
    
    func test_readRootNodes_whenFails_throws() async throws {
        let graphStoreConnection = FakeGraphStoreConnection()
        
        let testObject = GraphStoreAsyncInterface(graphStoreConnection: graphStoreConnection)
        
        let expectedScryError = ScryError.testInstance
        graphStoreConnection.requestReadRootNodes_error = expectedScryError

        do {
            let _ = try await testObject.readRootNodes(resource: Resource.testInstance)
            XCTFail("Should have thrown here")
        } catch {
            XCTAssertEqual(error.localizedDescription, expectedScryError.localizedDescription)
        }
    }
    
    func test_readNode_callsGraphStoreConnection() async throws {
        let graphStoreConnection = FakeGraphStoreConnection()
        
        let testObject = GraphStoreAsyncInterface(graphStoreConnection: graphStoreConnection)
        
        let expectedResource = Resource.testInstance
        let expectedIndex = Index.testInstance
        let expectedMode = ScryMode.random

        graphStoreConnection.requestReadNode_returnUpdate = GraphStoreUpdate.testInstance
        
        let _ = try await testObject.readNode(resource: expectedResource,
                                              index: expectedIndex,
                                              mode: expectedMode)

        XCTAssertEqual(graphStoreConnection.requestReadNode_calledCount, 1)
        XCTAssertEqual(graphStoreConnection.requestReadNode_paramResource, expectedResource)
        XCTAssertEqual(graphStoreConnection.requestReadNode_paramIndex, expectedIndex)
        XCTAssertEqual(graphStoreConnection.requestReadNode_paramMode, expectedMode)
    }
    
    func test_readNode_whenSucceeds_returnsUpdate() async throws {
        let graphStoreConnection = FakeGraphStoreConnection()
        
        let testObject = GraphStoreAsyncInterface(graphStoreConnection: graphStoreConnection)
        
        let expectedUpdate = GraphStoreUpdate.testInstance
        graphStoreConnection.requestReadNode_returnUpdate = expectedUpdate
        
        let update = try await testObject.readNode(resource: Resource.testInstance,
                                                   index: Index.testInstance,
                                                   mode: ScryMode.random)

        XCTAssertEqual(update, expectedUpdate)
    }
    
    func test_readNode_whenFails_throws() async throws {
        let graphStoreConnection = FakeGraphStoreConnection()
        
        let testObject = GraphStoreAsyncInterface(graphStoreConnection: graphStoreConnection)
        
        let expectedScryError = ScryError.testInstance
        graphStoreConnection.requestReadNode_error = expectedScryError

        do {
            let _ = try await testObject.readNode(resource: Resource.testInstance,
                                                  index: Index.testInstance,
                                                  mode: ScryMode.random)
            XCTFail("Should have thrown here")
        } catch {
            XCTAssertEqual(error.localizedDescription, expectedScryError.localizedDescription)
        }
    }
    
    func test_readChilren_callsGraphStoreConnection() async throws {
        let graphStoreConnection = FakeGraphStoreConnection()
        
        let testObject = GraphStoreAsyncInterface(graphStoreConnection: graphStoreConnection)
        
        let expectedResource = Resource.testInstance
        let expectedIndex = Index.testInstance
        let expectedMode = ScryMode.random

        graphStoreConnection.requestReadChildren_returnUpdate = GraphStoreUpdate.testInstance
        
        let _ = try await testObject.readChildren(resource: expectedResource,
                                                  index: expectedIndex,
                                                  mode: expectedMode)

        XCTAssertEqual(graphStoreConnection.requestReadChildren_calledCount, 1)
        XCTAssertEqual(graphStoreConnection.requestReadChildren_paramResource, expectedResource)
        XCTAssertEqual(graphStoreConnection.requestReadChildren_paramIndex, expectedIndex)
        XCTAssertEqual(graphStoreConnection.requestReadChildren_paramMode, expectedMode)
    }
    
    func test_readChildren_whenSucceeds_returnsUpdate() async throws {
        let graphStoreConnection = FakeGraphStoreConnection()

        let testObject = GraphStoreAsyncInterface(graphStoreConnection: graphStoreConnection)

        let expectedUpdate = GraphStoreUpdate.testInstance
        graphStoreConnection.requestReadChildren_returnUpdate = expectedUpdate

        let update = try await testObject.readChildren(resource: Resource.testInstance,
                                                       index: Index.testInstance,
                                                       mode: ScryMode.random)

        XCTAssertEqual(update, expectedUpdate)
    }

    func test_readChildren_whenFails_throws() async throws {
        let graphStoreConnection = FakeGraphStoreConnection()

        let testObject = GraphStoreAsyncInterface(graphStoreConnection: graphStoreConnection)

        let expectedScryError = ScryError.testInstance
        graphStoreConnection.requestReadChildren_error = expectedScryError

        do {
            let _ = try await testObject.readChildren(resource: Resource.testInstance,
                                                      index: Index.testInstance,
                                                      mode: ScryMode.random)
            XCTFail("Should have thrown here")
        } catch {
            XCTAssertEqual(error.localizedDescription, expectedScryError.localizedDescription)
        }
    }

    func test_createGraph_callsGraphStore() async throws {
        let graphStoreConnection = FakeGraphStoreConnection()

        let testObject = GraphStoreAsyncInterface(graphStoreConnection: graphStoreConnection)

        let resource = Resource.testInstance
        try await testObject.createGraph(resource: resource)

        XCTAssertEqual(graphStoreConnection.requestAddGraph_calledCount, 1)
        XCTAssertEqual(graphStoreConnection.requestAddGraph_paramResource, resource)
    }
    
    func test_createGraph_whenFails_throws() async throws {
        let graphStoreConnection = FakeGraphStoreConnection()

        let testObject = GraphStoreAsyncInterface(graphStoreConnection: graphStoreConnection)
        
        let pokeError = PokeError.testInstance
        graphStoreConnection.requestAddGraph_error = pokeError
        
        do {
            try await testObject.createGraph(resource: Resource.testInstance)
            XCTFail("Should have thrown here")
        } catch {
            XCTAssertEqual(error.localizedDescription,
                           pokeError.localizedDescription)
        }
    }
    
    func test_addNode_callsGraphStore() async throws {
        let graphStoreConnection = FakeGraphStoreConnection()

        let testObject = GraphStoreAsyncInterface(graphStoreConnection: graphStoreConnection)

        let resource = Resource.testInstance
        let post = Post.testInstance
        let children = Graph.testInstance
        try await testObject.addNode(resource: resource,
                                     post: post,
                                     children: children)

        XCTAssertEqual(graphStoreConnection.requestAddNodes_calledCount, 1)
        XCTAssertEqual(graphStoreConnection.requestAddNodes_paramResource, resource)
        XCTAssertEqual(graphStoreConnection.requestAddNodes_paramPost, post)
        XCTAssertEqual(graphStoreConnection.requestAddNodes_paramChildren, children)
    }
    
    func test_addNode_whenFails_throws() async throws {
        let graphStoreConnection = FakeGraphStoreConnection()

        let testObject = GraphStoreAsyncInterface(graphStoreConnection: graphStoreConnection)
        
        let pokeError = PokeError.testInstance
        graphStoreConnection.requestAddNodes_error = pokeError
        
        do {
            try await testObject.addNode(resource: Resource.testInstance,
                                         post: Post.testInstance,
                                         children: nil)
            XCTFail("Should have thrown here")
        } catch {
            XCTAssertEqual(error.localizedDescription,
                           pokeError.localizedDescription)
        }
    }
}
