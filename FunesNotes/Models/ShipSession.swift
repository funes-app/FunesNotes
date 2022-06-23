import Foundation
import Combine
import UrsusAtom
import UrsusHTTP
import SwiftGraphStore
import os

class ShipSession: ObservableObject, ShipSessioning {
    
    typealias GraphStoreInterfaceCreator = (URL, PatP) -> GraphStoreAsyncInterfacing
    typealias NoteGraphConnectorCreator = (Resource, GraphStoreAsyncInterfacing) -> NoteGraphConnecting

    var graphResource: Resource? {
        guard let ship = ship else { return nil }
        
        return resource(for: ship)
    }
    
    var ship: Ship?
    
    private(set) var noteGraphConnector: NoteGraphConnecting?
    
    private func resource(for ship: Ship) -> Resource {
        Resource(ship: ship, name: "funes-notes")
    }
            
    private var graphStoreAsyncInterface: GraphStoreAsyncInterfacing?
    
    private let credentialStore: CredentialStoring
    
    private var logger = Logger()
    private var cancellables: Set<AnyCancellable> = Set()

    @Published var connectionError: ConnectionError?
    var connectionErrorReceived: AnyPublisher<ConnectionError, Never> {
        $connectionError
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    @Published private var connectionStatus: ConnectionStatus
    var connectionStatusChanged: AnyPublisher<ConnectionStatus, Never> {
        $connectionStatus
            .eraseToAnyPublisher()
    }
    
    init(credentialStore: CredentialStoring = CredentialStore(),
         graphStoreInterfaceCreator: GraphStoreInterfaceCreator = ShipSession.defaultGraphStoreInterfaceCreator) {
        self.credentialStore = credentialStore
        
        let url = credentialStore
            .shipURL?
            .replacingEmptySchemeWithHTTPS
        let code = credentialStore
            .shipCode

        if let url = url,
           let code = code {
            graphStoreAsyncInterface = graphStoreInterfaceCreator(url, code)
            connectionStatus = .readyToConnect
        } else {
            connectionStatus = .notLoggedIn
        }
        
        if let graphStoreAsyncInterface = graphStoreAsyncInterface {
            setupGraphStoreSubscription(graphStoreConnection: graphStoreAsyncInterface.graphStoreConnection)
        }
    }
    
    func setupGraphStoreConnection(url: URL, code: PatP) {
        setupGraphStoreConnection(url: url,
                                  code: code,
                                  graphStoreInterfaceCreator: ShipSession.defaultGraphStoreInterfaceCreator)
    }
    
    internal func setupGraphStoreConnection(url: URL, code: PatP,
                                            graphStoreInterfaceCreator: GraphStoreInterfaceCreator) {
        credentialStore.saveCredentials(url: url, code: code)
        
        let graphStoreURL = url.replacingEmptySchemeWithHTTPS
        let graphStoreAsyncInterface = graphStoreInterfaceCreator(graphStoreURL, code)
        self.graphStoreAsyncInterface = graphStoreAsyncInterface
        setupGraphStoreSubscription(graphStoreConnection: graphStoreAsyncInterface.graphStoreConnection)
        connectionStatus = .readyToConnect
    }
    
    private func setupGraphStoreSubscription(graphStoreConnection: GraphStoreConnecting) {
        graphStoreConnection
            .graphStoreSubscription
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.error("Graph store connection failed: \(error.localizedDescription)")
                }
            }, receiveValue: { update in
                print(update)
            })
            .store(in: &cancellables)
    }
    
    func openConnection() async {
        await openConnection(graphConnectorCreator: ShipSession.defaultNoteGraphConnectorCreator)
    }
        
    internal func openConnection(graphConnectorCreator: NoteGraphConnectorCreator) async {
        guard let graphStoreAsyncInterface = graphStoreAsyncInterface else {
            logger.info("Attempting to connect without a graph store connection")
            return
        }
        
        do {
            connectionStatus = .loggingIn
            let ship = try await login(graphStoreInterface: graphStoreAsyncInterface)
            
            self.ship = ship
            
            let resource = resource(for: ship)
            
            self.noteGraphConnector = graphConnectorCreator(resource, graphStoreAsyncInterface)
            
            connectionStatus = .openingAirlock
            try await connect(graphStoreInterface: graphStoreAsyncInterface)

            connectionStatus = .subscribing
            try await startSubscription(graphStoreInterface: graphStoreAsyncInterface)
                        
            connectionStatus = .connected(ship: ship)
        } catch let error as ConnectionError {
            logConnectionError(error: error)
            credentialStore.clearCredentials()
            connectionError = error
            connectionStatus = .notLoggedIn
        } catch {
            logger.error("Unexpected exception trying to connect: \(error.localizedDescription)")
            credentialStore.clearCredentials()
            connectionStatus = .notLoggedIn
        }
    }
    
    private func logConnectionError(error: ConnectionError) {
        switch error {
        case .loginFailure(let error):
            logger.info("Unable to log into ship: \(error.localizedDescription)")
        case .connectFailure(let error):
            logger.info("Unable to open airlock for ship: \(error.localizedDescription)")
        case .startSubscriptionFailure(let error):
            logger.info("Unable to start subscription for ship: \(error.localizedDescription)")
        case .readGraphStoreFailure(let error):
            logger.info("Unable to read graph store on ship: \(error.localizedDescription)")
        case .createGraphFailure(let error):
            logger.info("Unable to create a new graph for notes: \(error.localizedDescription)")
        case .createRootNodeFailure(let error):
            logger.info("Unable to create a root node: \(error.localizedDescription)")
        }
    }
    
    private func login(graphStoreInterface: GraphStoreAsyncInterfacing) async throws -> Ship {
        do {
            return try await graphStoreInterface.login()
        } catch let error as LoginError {
            throw ConnectionError.loginFailure(error: error)
        }
    }
    
    private func connect(graphStoreInterface: GraphStoreAsyncInterfacing) async throws {
        do {
            try await graphStoreInterface.connect()
        } catch let error as ConnectError {
            throw ConnectionError.connectFailure(error: error)
        }
    }
    
    private func startSubscription(graphStoreInterface: GraphStoreAsyncInterfacing) async throws {
        do {
            try await graphStoreInterface.startSubscription()
        } catch let error as StartSubscriptionError {
            throw ConnectionError.startSubscriptionFailure(error: error)
        }
    }
        
    func logout() {
        credentialStore.clearCredentials()
        
        noteGraphConnector = nil
        
        connectionStatus = .notLoggedIn
    }
    
    static let defaultGraphStoreInterfaceCreator: GraphStoreInterfaceCreator = { (url: URL, code: PatP) in
        let airlockConnection = AirlockConnection(url: url, code: code)
        let connection = GraphStoreConnection(airlockConnection: airlockConnection)
        let interface = GraphStoreAsyncInterface(graphStoreConnection: connection)
        
        return interface
    }
    
    static let defaultNoteGraphConnectorCreator: NoteGraphConnectorCreator = {
        (resource: Resource, interface: GraphStoreAsyncInterfacing) in
        let graphManager = NoteGraphManager(resource: resource,
                                            graphStoreInterface: interface)
        return NoteGraphConnector(graphManager: graphManager)
    }
}
