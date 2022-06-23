import Combine
import SwiftUI
import UrsusAtom
import UrsusHTTP
import os

class AppViewModel: ObservableObject, AppViewModeling {
    typealias SynchronizerCreator = (NoteFileManaging,
                                     NoteGraphManaging,
                                     MetadataChangeMonitoring) -> GraphStoreSyncing
    var actionText: String {
        appSetupStatus.actionText
    }
    
    var appSetupStatus: AppSetupStatus {
        switch connectionStatus {
        case .notLoggedIn:
            return .notLoggedIn
        case .readyToConnect:
            return .readyToConnect
        case .connected:
            return appStatus(from: graphSetupStatus)
        default:
            return .connecting(connectionStatus)
        }
    }
    
    private func appStatus(from graphStatus: GraphSetupStatus) -> AppSetupStatus {
        if case .done = graphStatus {
            return appStatus(from: synchronizerStatus)
        }
        
        return .settingUpGraph(graphStatus)
        
    }
    
    private func appStatus(from synchronizerStatus: SynchronizerSetupStatus) -> AppSetupStatus {
        if case .setupComplete = synchronizerStatus {
            return .setupComplete
        }
        
        return .synchronizing(synchronizerStatus)
    }
    
    @Published private var connectionStatus: ConnectionStatus
    @Published private var graphSetupStatus: GraphSetupStatus
    @Published private var synchronizerStatus: SynchronizerSetupStatus
    
    @Published var showFileError = false
    var fileError: NoteFileError?

    @Published var showConnectionError = false
    var connectionError: ConnectionError?
    
    @Published var showGraphError = false
    var graphError: GraphStoreError?
        
    let fileConnector: FileConnecting
    let shipSession: ShipSessioning
    var graphStoreSync: GraphStoreSyncing?

    private var logger = Logger()
    private var cancellables: Set<AnyCancellable> = []
    
    init(fileConnector: FileConnecting,
         shipSession: ShipSessioning,
         dispatchQueue: DispatchQueue = DispatchQueue.main) {
        self.fileConnector = fileConnector
        self.shipSession = shipSession
        
        self.connectionStatus = .notLoggedIn
        self.graphSetupStatus = .ready
        self.synchronizerStatus = .ready
        
        fileConnector
            .fileError
            .receive(on: dispatchQueue)
            .sink(receiveValue: { [weak self] error in
                self?.setFileError(error)
            })
            .store(in: &cancellables)
        
        shipSession
            .connectionStatusChanged
            .receive(on: dispatchQueue)
            .assign(to: &$connectionStatus)

        shipSession
            .connectionStatusChanged
            .receive(on: dispatchQueue)
            .sink(receiveValue: { [weak self] status in
                if .readyToConnect == status {
                    self?.connectRequested()
                }
            })
            .store(in: &cancellables)
        
        shipSession
            .connectionErrorReceived
            .receive(on: dispatchQueue)
            .sink { [weak self] error in
                self?.connectionError = error
                self?.showConnectionError = true
            }
            .store(in: &cancellables)
    }
    
    func setupGraphStoreRequested(url: URL?, key: PatP?) {
        guard let url = url,
              let key = key else {
                  logger.info("Attempting to request connection with a nil value for URL and/or +code")
            return
        }

        shipSession.setupGraphStoreConnection(url: url, code: key)
    }
    
    func connectRequested() {
        Task {
            await connectRequested(synchronizerCreator: GraphStoreSync.init)
        }
    }
    
    internal func connectRequested(synchronizerCreator: SynchronizerCreator,
                                   dispatchQueue: DispatchQueue = .main) async {
        await shipSession.openConnection()
        
        guard let noteGraphConnector = shipSession.noteGraphConnector else {
            return
        }
        
        subscribeToGraphConnector(noteGraphConnector, dispatchQueue)
        
        await noteGraphConnector.setupGraph()

        graphStoreSync = synchronizerCreator(fileConnector.noteFileManager,
                                             noteGraphConnector.graphManager,
                                             fileConnector.metadataChangeMonitor)
        
        guard let graphStoreSynchronizer = graphStoreSync else {
            return
        }
        
        subscribeToSynchronizer(graphStoreSynchronizer, dispatchQueue)

        graphStoreSynchronizer.start()

        await setSynchronizerStatus(.synchronizing)
        await graphStoreSynchronizer.synchronize()

        await setSynchronizerStatus(.setupComplete)
    }
    
    func logout() async {
        connectionStatus = .loggingOut
        await graphStoreSync?.synchronize()

        shipSession.logout()

        fileConnector.stopMonitor()

        fileConnector.deleteAllFiles()
    }
    
    @MainActor
    private func setSynchronizerStatus(_ synchronizerStatus: SynchronizerSetupStatus) {
        self.synchronizerStatus = synchronizerStatus
    }
    
    private func setGraphError(_ graphError: GraphStoreError) {
        self.graphError = graphError
        showGraphError = true
    }
    
    private func setFileError(_ fileError: NoteFileError) {
        self.fileError = fileError
        showFileError = true
    }
    
    private func subscribeToGraphConnector(_ noteGraphConnector: NoteGraphConnecting,
                                           _ dispatchQueue: DispatchQueue) {
        noteGraphConnector
            .graphSetupStatusChanged
            .receive(on: dispatchQueue)
            .assign(to: &$graphSetupStatus)
        
        noteGraphConnector
            .graphStoreError
            .receive(on: dispatchQueue)
            .sink { [weak self] in self?.setGraphError($0) }
            .store(in: &cancellables)
    }
    
    private func subscribeToSynchronizer(_ graphStoreSync: GraphStoreSyncing,
                                         _ dispatchQueue: DispatchQueue) {
        graphStoreSync
            .fileError
            .receive(on: dispatchQueue)
            .sink { [weak self] in self?.setFileError($0) }
            .store(in: &cancellables)
        
        graphStoreSync
            .graphStoreError
            .receive(on: dispatchQueue)
            .sink { [weak self] in self?.setGraphError($0) }
            .store(in: &cancellables)
    }
}
