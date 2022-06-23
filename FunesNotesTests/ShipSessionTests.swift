import XCTest
import UrsusAtom
import SwiftGraphStore 
import SwiftGraphStoreFakes
import UrsusHTTP
import Alamofire
@testable import FunesNotes

class ShipSessionTests: XCTestCase {
    func test_doesNotRetain() async {
        var testObject: ShipSession? = ShipSession(credentialStore: FakeCredentialStore())
        var graphStoreInterface: FakeGraphStoreAsyncInterface? = FakeGraphStoreAsyncInterface()
        graphStoreInterface?.login_returnShip = Ship.random
        var graphConnector: FakeNoteGraphConnector? = FakeNoteGraphConnector()

        setupGraphStoreInterface(testObject: testObject!,
                                 graphStoreInterface: graphStoreInterface!)
                
        await testObject?.openConnection(graphConnectorCreator: { _,_  in
            graphConnector!
        })
        
        weak var weakTestObject = testObject
        testObject = nil
        graphStoreInterface = nil
        graphConnector = nil
        XCTAssertNil(weakTestObject)
    }
    
    func test_init_setsConnectionStatusAndCreatesGSInterface() async throws {
        let credentialStore = FakeCredentialStore()
        
        let url = URL(string: "https://urbit.org")!
        let code = PatP.random
        credentialStore.shipURL = url
        credentialStore.shipCode = code
        
        var paramURL: URL?
        var paramCode: PatP?
        let graphStoreCreator: ShipSession.GraphStoreInterfaceCreator = {
            (url: URL, code: PatP) in
            paramURL = url
            paramCode = code

            return FakeGraphStoreAsyncInterface()
        }
        
        let testObject = ShipSession(credentialStore: credentialStore,
                                     graphStoreInterfaceCreator: graphStoreCreator)

        let publisher = testObject
            .connectionStatusChanged
            .assertNoFailure()
            .eraseToAnyPublisher()
        let connectionStatus = try await waitForResult(publisher)

        XCTAssertEqual(connectionStatus, ConnectionStatus.readyToConnect)
        XCTAssertEqual(paramURL, url)
        XCTAssertEqual(paramCode, code)
    }
    
    func test_init_whenURLMissingScheme_addsHTTPS() async throws {
        let credentialStore = FakeCredentialStore()

        var paramURL: URL?
        let graphStoreCreator: ShipSession.GraphStoreInterfaceCreator = {
            (url: URL, _) in
            paramURL = url
            
            return FakeGraphStoreAsyncInterface()
        }

        credentialStore.shipURL = URL(string: "urbit.org")!
        credentialStore.shipCode = PatP.random

        let testObject = ShipSession(credentialStore: credentialStore,
                                     graphStoreInterfaceCreator: graphStoreCreator)
        XCTAssertNotNil(testObject)

        let expectedURL = URL(string: "https:urbit.org")!
        XCTAssertEqual(paramURL, expectedURL)
    }

    func test_init_whenMissingAuthInfo_setsConnectionStatusToNotLoggedIn() async throws {
        let credentialStore = FakeCredentialStore()
        credentialStore.shipURL = URL(string: "https://urbit.org")!
        credentialStore.shipCode = nil
        var testObject = ShipSession(credentialStore: credentialStore)

        var publisher = testObject
            .connectionStatusChanged
            .assertNoFailure()
            .eraseToAnyPublisher()
        var connectionStatus = try await waitForResult(publisher)

        XCTAssertEqual(connectionStatus, ConnectionStatus.notLoggedIn)

        credentialStore.shipURL = nil
        credentialStore.shipCode = "ribben-donnyl"
        testObject = ShipSession(credentialStore: credentialStore)

        publisher = testObject
            .connectionStatusChanged
            .assertNoFailure()
            .eraseToAnyPublisher()
        connectionStatus = try await waitForResult(publisher)

        XCTAssertEqual(connectionStatus, ConnectionStatus.notLoggedIn)
    }
    
    func test_setupGraphStoreConnection_updatesStatusToReady() async throws{
        let testObject = ShipSession(credentialStore: FakeCredentialStore())

        testObject.setupGraphStoreConnection(url: URL(string: "https://funes.app")!,
                                             code: PatP.random)
        
        let publisher = testObject
            .connectionStatusChanged
            .assertNoFailure()
            .eraseToAnyPublisher()
        let connectionStatus = try await waitForResult(publisher)
        
        XCTAssertEqual(connectionStatus, .readyToConnect)
    }
    
    func test_setupGraphStoreConnection_savesParameterstoCredentialStore() {
        let credentialStore = FakeCredentialStore()
        let testObject = ShipSession(credentialStore: credentialStore)
        
        credentialStore.shipURL = nil
        credentialStore.shipCode = nil

        let url = URL(string: "https://funes.app")!
        let code = PatP.random
        testObject.setupGraphStoreConnection(url: url, code: code)
        
        XCTAssertEqual(credentialStore.saveCredentials_calledCount, 1)
        XCTAssertEqual(credentialStore.saveCredentials_paramURL, url)
        XCTAssertEqual(credentialStore.saveCredentials_paramCode, code)
    }
    
    func test_setupGraphStoreConnection_whenURLMissingScheme_usesHTTPS() {
        var paramURL: URL?
        let graphStoreCreator: ShipSession.GraphStoreInterfaceCreator = {
            (url: URL, _) in
            paramURL = url
            
            return FakeGraphStoreAsyncInterface()
        }
        
        let credentialStore = FakeCredentialStore()
        let testObject = ShipSession(credentialStore: credentialStore)
        
        let url = URL(string: "funes.app")!
        let code = PatP.random
        testObject.setupGraphStoreConnection(
            url: url,
            code: code,
            graphStoreInterfaceCreator: graphStoreCreator
            )
        
        let urlWithScheme = URL(string: "https:funes.app")!
        
        XCTAssertEqual(credentialStore.saveCredentials_paramURL, url)
        XCTAssertEqual(paramURL, urlWithScheme)
    }
    
    func test_openConnection_callsLogin() async {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()

        let testObject = ShipSession(credentialStore: FakeCredentialStore())
        
        setupGraphStoreInterface(testObject: testObject,
                                 graphStoreInterface: graphStoreInterface)
        
        await testObject.openConnection(graphConnectorCreator: defaultGraphConnectorCreator)

        XCTAssertEqual(graphStoreInterface.login_calledCount, 1)
    }
    
    func test_openConnection_whenLoginFails_resetsWithError() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()

        let credentialStore = FakeCredentialStore()
        let testObject = ShipSession(credentialStore: credentialStore)
        setupGraphStoreInterface(testObject: testObject,
                                 graphStoreInterface: graphStoreInterface)

        let expectedLoginError = LoginError.httpsRequired
        graphStoreInterface.login_error = expectedLoginError
        
        credentialStore.shipURL = URL(string: "url")!
        credentialStore.shipCode = PatP.random
        
        await testObject.openConnection(graphConnectorCreator: defaultGraphConnectorCreator)
        
        let expectedConnectError = ConnectionError.loginFailure(error: expectedLoginError)
        try await verifyReset(testObject: testObject,
                              credentialStore: credentialStore,
                              expectedError: expectedConnectError)
    }
    
    func test_openConnection_whenLoginSucceeds_createsGraphManager() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()

        let testObject = ShipSession(credentialStore: FakeCredentialStore())
        setupGraphStoreInterface(testObject: testObject,
                                 graphStoreInterface: graphStoreInterface)
        
        let ship = Ship.testInstance
        graphStoreInterface.login_returnShip = ship
        
        var creator_calledCount = 0
        var creator_paramInterface: GraphStoreAsyncInterfacing?
        var creator_paramResource: Resource?
        func creator(resource: Resource,
                     interface: GraphStoreAsyncInterfacing) -> NoteGraphConnecting {
            creator_calledCount += 1
            creator_paramInterface = interface
            creator_paramResource = resource
            
            return FakeNoteGraphConnector()
        }

        await testObject.openConnection(graphConnectorCreator: creator)
        
        XCTAssertEqual(creator_calledCount, 1)
        let fakeInterface = try XCTUnwrap(creator_paramInterface as? FakeGraphStoreAsyncInterface)
        XCTAssert(fakeInterface === graphStoreInterface)
        let expectedResource = Resource(ship: ship, name: "funes-notes")
        XCTAssertEqual(creator_paramResource, expectedResource)
    }
    
    func test_openConnection_whenLoginSucceeds_callsConnect() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()

        let testObject = ShipSession(credentialStore: FakeCredentialStore())
        setupGraphStoreInterface(testObject: testObject,
                                 graphStoreInterface: graphStoreInterface)

        await testObject.openConnection(graphConnectorCreator: defaultGraphConnectorCreator)
        
        XCTAssertEqual(graphStoreInterface.connect_calledCount, 1)
    }
    
    func test_openConnection_whenLoginSucceeds_setsShip() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()

        let testObject = ShipSession(credentialStore: FakeCredentialStore())
        setupGraphStoreInterface(testObject: testObject,
                                 graphStoreInterface: graphStoreInterface)

        XCTAssertNil(testObject.ship)
        
        let ship = Ship.testInstance
        graphStoreInterface.login_returnShip = ship

        await testObject.openConnection(graphConnectorCreator: defaultGraphConnectorCreator)
        
        XCTAssertEqual(testObject.ship, ship)
    }

    func test_openConnection_whenConnectFails_resets() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()

        let credentialStore = FakeCredentialStore()
        let testObject = ShipSession(credentialStore: credentialStore)
        setupGraphStoreInterface(testObject: testObject,
                                 graphStoreInterface: graphStoreInterface)
        
        let expectedConnectError = ConnectError.connectFailed(message: UUID().uuidString)
        graphStoreInterface.connect_error = expectedConnectError

        credentialStore.shipURL = URL(string: "url")!
        credentialStore.shipCode = PatP.random
        
        await testObject.openConnection(graphConnectorCreator: defaultGraphConnectorCreator)
        
        try await verifyReset(testObject: testObject,
                              credentialStore: credentialStore,
                              expectedError: expectedConnectError)
    }
    
    func test_openConnection_whenConnectSucceeds_callSubscribe() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()

        let testObject = ShipSession(credentialStore: FakeCredentialStore())
        setupGraphStoreInterface(testObject: testObject,
                                 graphStoreInterface: graphStoreInterface)

        graphStoreInterface.connect_error = nil
        
        await testObject.openConnection(graphConnectorCreator: defaultGraphConnectorCreator)
        
        XCTAssertEqual(graphStoreInterface.startSubscription_calledCount, 1)
    }
    
    func test_openConnection_whenSubscriptionFails_resets() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()

        let credentialStore = FakeCredentialStore()
        credentialStore.shipURL = URL(string: "url")!
        credentialStore.shipCode = PatP.random

        let testObject = ShipSession(credentialStore: credentialStore)
        setupGraphStoreInterface(testObject: testObject,
                                 graphStoreInterface: graphStoreInterface)
        
        let expectedSubscriptionError = StartSubscriptionError.startSubscriptionFailed(message: UUID().uuidString)
        graphStoreInterface.startSubscription_error = expectedSubscriptionError
        
        await testObject.openConnection(graphConnectorCreator: defaultGraphConnectorCreator)
        
        try await verifyReset(testObject: testObject,
                              credentialStore: credentialStore,
                              expectedError: expectedSubscriptionError)
    }
    
    func test_logout_clearsUserDefaults() {
        let credentialStore = FakeCredentialStore()
        let testObject = ShipSession(credentialStore: credentialStore)

        credentialStore.shipURL = URL(string: "http://urbit.org")!
        credentialStore.shipCode = PatP.random
        
        testObject.logout()
        XCTAssertEqual(credentialStore.clearCredentials_calledCount, 1)
    }
    
    func test_logout_clearsNoteGraphConnection() async {
        let credentialStore = FakeCredentialStore()
        credentialStore.shipCode = PatP.testInstance
        credentialStore.shipURL = URL(string: "http://funes.app")!
        let testObject = ShipSession(credentialStore: credentialStore)

        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        setupGraphStoreInterface(testObject: testObject,
                                 graphStoreInterface: graphStoreInterface)
    
        await testObject.openConnection(graphConnectorCreator: { _,_ in
            FakeNoteGraphConnector()
        })

        XCTAssertNotNil(testObject.noteGraphConnector)
        
        testObject.logout()
        
        XCTAssertNil(testObject.noteGraphConnector)
    }
        
    private func setupGraphStoreInterface(testObject: ShipSession,
                                          graphStoreInterface: GraphStoreAsyncInterfacing) {
        
        let creator: ShipSession.GraphStoreInterfaceCreator = { _,_ in
            graphStoreInterface
        }
        testObject.setupGraphStoreConnection(url: URL(string: "url")!,
                                             code: PatP.random,
                                             graphStoreInterfaceCreator: creator)
    }
    
    fileprivate func setupSuccessfulConnection(_ graphStoreConnection: FakeGraphStoreConnection,
                                               _ graphStoreInterface: FakeGraphStoreAsyncInterface,
                                               _ ship: PatP) {
        graphStoreConnection.ship = ship
        graphStoreInterface.login_returnShip = ship
        graphStoreInterface.connect_error = nil
        graphStoreInterface.startSubscription_error = nil
    }
    
    fileprivate func verifyReset(testObject: ShipSession,
                                 credentialStore: FakeCredentialStore,
                                 expectedError: LocalizedError) async throws {
        let statusPublisher = testObject
            .connectionStatusChanged
            .eraseToAnyPublisher()
        let connectionStatus = try await waitForResult(statusPublisher)
        
        let errorPublisher = testObject
            .connectionErrorReceived
            .eraseToAnyPublisher()
        let publishedError = try await waitForResult(errorPublisher)

        XCTAssertEqual(connectionStatus, .notLoggedIn)
        XCTAssertEqual(publishedError.localizedDescription, expectedError.localizedDescription)
        XCTAssertEqual(credentialStore.clearCredentials_calledCount, 1)
    }
    
    fileprivate let defaultGraphConnectorCreator: ShipSession.NoteGraphConnectorCreator = { _,_ in FakeNoteGraphConnector() }
    
}
