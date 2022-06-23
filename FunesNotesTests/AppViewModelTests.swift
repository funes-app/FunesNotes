@testable import FunesNotes
import XCTest
import UrsusAtom
import UrsusHTTP
import SwiftGraphStore

class AppViewModelTests: XCTestCase {
    func test_doesNotRetain() async {
        let session = FakeShipSession()
        session.noteGraphConnector = FakeNoteGraphConnector()
        
        var testObject: AppViewModel? = AppViewModel(fileConnector: FakeFileConnector(),
                                                     shipSession: session)
        
        await testObject?.connectRequested(synchronizerCreator: synchronizerCreatorCreator())

        weak var weakTestObject = testObject
        testObject = nil
        XCTAssertNil(weakTestObject)
    }
    
    func test_fileError_passesThroughFromFileConnection() {
        let fileConnector = FakeFileConnector()
                
        let queue = DispatchQueue(label: "test queue")
        let testObject = AppViewModel(fileConnector: fileConnector,
                                      shipSession: FakeShipSession(),
                                      dispatchQueue: queue)
        
        XCTAssertNil(testObject.fileError)
        XCTAssertEqual(testObject.showFileError, false)

        let expectedError = NoteFileError.loadFailure(error: CocoaError(.coderValueNotFound))
        fileConnector._fileError = expectedError
        
        queue.sync {}

        XCTAssertEqual(testObject.fileError, expectedError)
        XCTAssertEqual(testObject.showFileError, true)
    }
    
    func test_connectionError_passesThroughFromSession() {
        let session = FakeShipSession()
        
        let queue = DispatchQueue(label: "test queue")
        let testObject = AppViewModel(fileConnector: FakeFileConnector(),
                                      shipSession: session,
                                      dispatchQueue: queue)

        XCTAssertNil(testObject.connectionError)
        XCTAssertEqual(testObject.showConnectionError, false)
        
        let expectedLoginError = LoginError.badCode
        let expectedError = ConnectionError.loginFailure(error: expectedLoginError)
        session.connectionError = expectedError
                
        queue.sync {}

        XCTAssertEqual(testObject.showConnectionError, true)
        guard case let .loginFailure(loginError) = testObject.connectionError,
              case .badCode = loginError else {
                  XCTFail("Unexpected error: \(String(describing: testObject.connectionError))")
                  return
              }
    }
    
    func test_init_setsConnectionStatusFromSession() {
        let connectionStatus = ConnectionStatus.readyToConnect
        let session = FakeShipSession(connectionStatus: connectionStatus)
        let queue = DispatchQueue(label: "test queue")

        let testObject = AppViewModel(fileConnector: FakeFileConnector(),
                                      shipSession: session,
                                      dispatchQueue: queue)
        queue.sync {}
        XCTAssertEqual(testObject.appSetupStatus, .readyToConnect)
    }
    
    func test_setupGraphStoreRequested_createsAirlock() {
        let session = FakeShipSession()
        let testObject = AppViewModel(fileConnector: FakeFileConnector(),
                                      shipSession: session)
        
        let url = URL(string: "http://funes.app")
        let key = PatP.random
        
        testObject.setupGraphStoreRequested(url: url, key: key)
        
        XCTAssertEqual(session.setupGraphStoreConnection_calledCount, 1)
        XCTAssertEqual(session.setupGraphStoreConnection_paramURL, url)
        XCTAssertEqual(session.setupGraphStoreConnection_paramCode, key)
    }
    
    func test_connectStatusChanged_whenStatusIsReadyToConnect_connects() async {
        let session = FakeShipSession()
        let queue = DispatchQueue(label: "app vm test")
        let testObject = AppViewModel(fileConnector: FakeFileConnector(),
                                      shipSession: session,
                                      dispatchQueue: queue)
        
        session.connectionStatus = .loggingIn
        
        queue.sync {}
        await Task.yield()
                
        XCTAssertEqual(session.openConnection_calledCount, 0)
        
        session.connectionStatus = .readyToConnect
        
        queue.sync {}
        await Task.yield()
                
        XCTAssertEqual(session.openConnection_calledCount, 1)
        
        await testObject.logout()
    }
    
    func test_connectRequested_opensConnection() async {
        let session = FakeShipSession()
        let testObject = AppViewModel(fileConnector: FakeFileConnector(),
                                      shipSession: session)
        
        await testObject.connectRequested(synchronizerCreator: synchronizerCreatorCreator())
        
        XCTAssertEqual(session.openConnection_calledCount, 1)
    }
    
    func test_connectRequested_whenConnectionOpens_setsUpGraphStoreConnection() async {
        let session = FakeShipSession()
        let noteGraphConnector = FakeNoteGraphConnector()
        session.noteGraphConnector = noteGraphConnector

        let testObject = AppViewModel(fileConnector: FakeFileConnector(),
                                      shipSession: session)
        
        await testObject.connectRequested(synchronizerCreator: synchronizerCreatorCreator())

        XCTAssertEqual(noteGraphConnector.setupGraph_calledCount, 1)
    }
        
    func test_connectRequested_whenGraphStoreConnectionSucceeds_createsSynchronizer() async {
        let fileConnector = FakeFileConnector()
        let session = FakeShipSession()

        let testObject = AppViewModel(fileConnector: fileConnector,
                                      shipSession: session)

        var synchronizerCreator_calledCount = 0
        var synchronizerCreator_paramFileManager: NoteFileManaging?
        var synchronizerCreator_paramGraphManager: NoteGraphManaging?
        var synchronizerCreator_paramMetadataMonitor: MetadataChangeMonitoring?
        let returnedSynchronizer = FakeGraphStoreSync()
        func synchronizerCreator(fileManager: NoteFileManaging,
                                 graphManager: NoteGraphManaging,
                                 metadataMonitor: MetadataChangeMonitoring) -> GraphStoreSyncing {
            synchronizerCreator_calledCount += 1
            synchronizerCreator_paramFileManager = fileManager
            synchronizerCreator_paramGraphManager = graphManager
            synchronizerCreator_paramMetadataMonitor = metadataMonitor

            return returnedSynchronizer
        }

        let fileManager = FakeNoteFileManager()
        fileConnector.noteFileManager = fileManager
        let metadataMonitor = FakeMetadataChangeMonitor()
        fileConnector.metadataChangeMonitor = metadataMonitor
        
        let noteGraphManager = FakeNoteGraphManager()
        let noteGraphConnector = FakeNoteGraphConnector()
        noteGraphConnector.graphManager = noteGraphManager
        session.noteGraphConnector = noteGraphConnector

        await testObject.connectRequested(synchronizerCreator: synchronizerCreator)

        XCTAssertEqual(synchronizerCreator_calledCount, 1)
        XCTAssert(synchronizerCreator_paramFileManager as? FakeNoteFileManager === fileManager)
        XCTAssert(synchronizerCreator_paramGraphManager as? FakeNoteGraphManager === noteGraphManager)
        XCTAssert(synchronizerCreator_paramMetadataMonitor as? FakeMetadataChangeMonitor === metadataMonitor)
        XCTAssert(testObject.graphStoreSync as? FakeGraphStoreSync === returnedSynchronizer)
    }
    
    func test_connectRequested_whenGraphStoreConnectionSucceeds_startsSynchronizer() async {
        let session = FakeShipSession()
        session.noteGraphConnector = FakeNoteGraphConnector()

        let graphStoreSynchronizer = FakeGraphStoreSync()
        
        let testObject = AppViewModel(fileConnector: FakeFileConnector(),
                                      shipSession: session)
        
        await testObject.connectRequested(synchronizerCreator: { _,_,_ in
            graphStoreSynchronizer
        })

        XCTAssertEqual(graphStoreSynchronizer.start_calledCount, 1)
    }
    
    func test_connectRequested_performsSynchronize() async {
        let session = FakeShipSession()
        session.noteGraphConnector = FakeNoteGraphConnector()
        
        let testObject = AppViewModel(fileConnector: FakeFileConnector(),
                                      shipSession: session)
        
        let graphStoreSynchronizer = FakeGraphStoreSync()
        await testObject.connectRequested(synchronizerCreator: synchronizerCreatorCreator(graphStoreSynchronizer))
        DispatchQueue.main.sync {}

        XCTAssertEqual(graphStoreSynchronizer.synchronize_calledCount, 1)
    }
    
    func test_connectRequested_whenFinished_updatesStatus() async {
        let session = FakeShipSession()
        let graphConnector = FakeNoteGraphConnector()
        session.noteGraphConnector = graphConnector
        
        let graphStoreSynchronizer = FakeGraphStoreSync()
        
        let testObject = AppViewModel(fileConnector: FakeFileConnector(),
                                      shipSession: session)
        
        session.connectionStatus = .connected(ship: Ship.random)
        graphConnector._graphSetupStatusChanged = .done
        
        await testObject.connectRequested(synchronizerCreator: synchronizerCreatorCreator(graphStoreSynchronizer))

        XCTAssertEqual(testObject.appSetupStatus, .setupComplete)
    }
    
    func test_connectRequested_updatesAppStatusBasedOnGraphStatus() async throws {
        let session = FakeShipSession()
        let noteGraphConnector = FakeNoteGraphConnector()
        session.noteGraphConnector = noteGraphConnector

        let testObject = AppViewModel(fileConnector: FakeFileConnector(),
                                      shipSession: session)

        await testObject.connectRequested(synchronizerCreator: synchronizerCreatorCreator())

        session.connectionStatus = .connected(ship: Ship.random)
        noteGraphConnector._graphSetupStatusChanged = .creatingGraph
        
        DispatchQueue.main.sync {}

        XCTAssertEqual(testObject.appSetupStatus, .settingUpGraph(.creatingGraph))
        
        noteGraphConnector._graphSetupStatusChanged = .creatingRootNode
        
        DispatchQueue.main.sync {}

        XCTAssertEqual(testObject.appSetupStatus, .settingUpGraph(.creatingRootNode))
        
        noteGraphConnector._graphSetupStatusChanged = .done
        
        DispatchQueue.main.sync {}

        XCTAssertEqual(testObject.appSetupStatus, .setupComplete)
    }

    func test_connectRequested_setsUpGraphConnectionErrorPublisher() async throws {
        let session = FakeShipSession()
        let graphConnector = FakeNoteGraphConnector()
        session.noteGraphConnector = graphConnector

        let testObject = AppViewModel(fileConnector: FakeFileConnector(),
                                      shipSession: session)

        let dispatchQueue = DispatchQueue(label: "connect test")
        await testObject.connectRequested(synchronizerCreator: synchronizerCreatorCreator(),
                                          dispatchQueue: dispatchQueue)
                
        let expectedReadError = GraphStoreReadError.readFailure(error: ScryError.testInstance)
        let expectedGraphError = GraphStoreError.readError(error: expectedReadError)
        graphConnector._graphStoreError = expectedGraphError

        dispatchQueue.sync { }
        try await Task.sleep(nanoseconds: 20_000_000)

        XCTAssertEqual(testObject.showGraphError, true)

        let graphError = try XCTUnwrap(testObject.graphError)
        guard case GraphStoreError.readError(let readError) = graphError else {
            XCTFail("Invalid error: \(graphError.localizedDescription)")
            return
        }
        XCTAssertEqual(readError.errorDescription, expectedReadError.errorDescription)
    }
    
    func test_connectRequested_setsUpGraphConnectionStatusPublisher() async throws {
        let session = FakeShipSession()
        let graphConnector = FakeNoteGraphConnector()
        session.noteGraphConnector = graphConnector

        let testObject = AppViewModel(fileConnector: FakeFileConnector(),
                                      shipSession: session)

        let dispatchQueue = DispatchQueue(label: "connect test")
        await testObject.connectRequested(synchronizerCreator: synchronizerCreatorCreator(),
                                          dispatchQueue: dispatchQueue)
        
        session.connectionStatus = .connected(ship: Ship.testInstance)
        dispatchQueue.sync { }
        try await Task.sleep(nanoseconds: 20_000_000)

        let graphSetupStatus = GraphSetupStatus.creatingRootNode
        graphConnector._graphSetupStatusChanged = graphSetupStatus
        dispatchQueue.sync { }
        try await Task.sleep(nanoseconds: 20_000_000)
        
        let status = try XCTUnwrap(testObject.appSetupStatus)
        
        let expectedStatus = AppSetupStatus.settingUpGraph(graphSetupStatus)
        XCTAssertEqual(status, expectedStatus)
    }
    
    func test_connectRequested_setsUpSynchronizerFileErrorPublisher() async throws {
        let session = FakeShipSession()
        let graphConnector = FakeNoteGraphConnector()
        session.noteGraphConnector = graphConnector

        let testObject = AppViewModel(fileConnector: FakeFileConnector(),
                                      shipSession: session)

        let graphStoreSynchronizer = FakeGraphStoreSync()
        let dispatchQueue = DispatchQueue(label: "connect test")
        await testObject.connectRequested(synchronizerCreator: synchronizerCreatorCreator(graphStoreSynchronizer),
                                          dispatchQueue: dispatchQueue)
        
        let internalError = NSError(domain: UUID().uuidString, code: 0)
        let expectedFileError = NoteFileError.loadFailure(error: internalError)
        graphStoreSynchronizer._fileError = expectedFileError

        dispatchQueue.sync { }
        
        XCTAssertEqual(testObject.showFileError, true)
        XCTAssertEqual(testObject.fileError, expectedFileError)
    }
    
    func test_connectRequested_setsUpSynchronizerGraphErrorPublisher() async throws {
        let session = FakeShipSession()
        let graphConnector = FakeNoteGraphConnector()
        session.noteGraphConnector = graphConnector

        let testObject = AppViewModel(fileConnector: FakeFileConnector(),
                                      shipSession: session)

        let graphStoreSynchronizer = FakeGraphStoreSync()
        let dispatchQueue = DispatchQueue(label: "connect test")
        await testObject.connectRequested(synchronizerCreator: synchronizerCreatorCreator(graphStoreSynchronizer),
                                          dispatchQueue: dispatchQueue)
        
        let internalError = NSError(domain: UUID().uuidString, code: 0)
        let expectedFileError = NoteFileError.loadFailure(error: internalError)
        graphStoreSynchronizer._fileError = expectedFileError

        dispatchQueue.sync { }
        
        XCTAssertEqual(testObject.showFileError, true)
        XCTAssertEqual(testObject.fileError, expectedFileError)
    }
    
    func test_connectionStatusPublished_updatesAppStatus() {
        let session = FakeShipSession()
        let queue = DispatchQueue(label: "test queue")

        let testObject = AppViewModel(fileConnector: FakeFileConnector(),
                                      shipSession: session,
                                      dispatchQueue: queue)

        session.connectionStatus = .notLoggedIn
                
        queue.sync {}

        XCTAssertEqual(testObject.appSetupStatus, .notLoggedIn)
    
        session.connectionStatus = .readyToConnect
        queue.sync {}
        
        XCTAssertEqual(testObject.appSetupStatus, .readyToConnect)
        
        session.connectionStatus = .openingAirlock
        queue.sync {}
        
        XCTAssertEqual(testObject.appSetupStatus, .connecting(.openingAirlock))

        session.connectionStatus = .connected(ship: Ship.random)
        queue.sync {}
        
        XCTAssertEqual(testObject.appSetupStatus, .settingUpGraph(.ready))
    }
    
    func test_logout_callsSynchronize() async {
        let graphStoreSync = FakeGraphStoreSync()

        let testObject = AppViewModel()
        await testObject.addGraphStoreSync(graphStoreSync)

        XCTAssertEqual(graphStoreSync.synchronize_calledCount, 1)
                
        await testObject.logout()
        
        XCTAssertEqual(graphStoreSync.synchronize_calledCount, 2)
    }
    
    func test_logout_callsLogoutOnSession() async {
        let session = FakeShipSession()
        let testObject = AppViewModel(shipSession: session)
        
        await testObject.logout()

        XCTAssertEqual(session.logout_calledCount, 1)
    }

    func test_logout_stopsMetadataMonitor() async {
        let fileConnector = FakeFileConnector()
        let testObject = AppViewModel(fileConnector: fileConnector)

        await testObject.logout()

        XCTAssertEqual(fileConnector.stopMonitor_calledCount, 1)
    }

    func test_logout_deletesAllFiles() async {
        let fileConnector = FakeFileConnector()
        let testObject = AppViewModel(fileConnector: fileConnector)

        await testObject.logout()

        XCTAssertEqual(fileConnector.deleteAllFiles_calledCount, 1)
    }
}

extension AppViewModel {
    convenience init() {
        let shipSession = FakeShipSession()
        shipSession.noteGraphConnector = FakeNoteGraphConnector()
        
        self.init(shipSession: shipSession)
    }
    
    convenience init(fileConnector: FileConnecting) {
        self.init(fileConnector: fileConnector,
                  shipSession: FakeShipSession())
    }
    
    convenience init(shipSession: ShipSessioning) {
        self.init(fileConnector: FakeFileConnector(),
                  shipSession: shipSession)
    }
    
    func addGraphStoreSync(_ graphStoreSync: GraphStoreSyncing) async {
        await connectRequested(synchronizerCreator: synchronizerCreatorCreator(graphStoreSync))
        DispatchQueue.main.sync { }
    }
}

fileprivate func synchronizerCreatorCreator(_ graphStoreSync: GraphStoreSyncing = FakeGraphStoreSync()) -> AppViewModel.SynchronizerCreator {
    return { _,_,_ -> GraphStoreSyncing in
        graphStoreSync
    }
}
