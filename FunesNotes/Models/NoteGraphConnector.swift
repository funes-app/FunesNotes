import Foundation
import Combine
import os

class NoteGraphConnector: NoteGraphConnecting {    
    private let logger = Logger()
    
    @Published var _graphStoreError: GraphStoreError?
    var graphStoreError: AnyPublisher<GraphStoreError, Never> {
        $_graphStoreError
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    @Published var _graphSetupStatusChanged: GraphSetupStatus?
    var graphSetupStatusChanged: AnyPublisher<GraphSetupStatus, Never> {
        $_graphSetupStatusChanged
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    let graphManager: NoteGraphManaging
    
    init(graphManager: NoteGraphManaging) {
        self.graphManager = graphManager
        self._graphSetupStatusChanged = .ready
        
        graphManager
            .graphSetupStatusChanged
            .map { Optional($0) }
            .assign(to: &$_graphSetupStatusChanged)
    }
    
    func setupGraph() async {
        do {
            try await graphManager.setupGraph()
        } catch let error as GraphStoreError {
            _graphStoreError = error
        } catch {
            logger.info("Unhandled exception setting up graph: \(error.localizedDescription)")
        }
    }
    
    func downloadAllIds() async -> [NoteId] {
        do {
            return try await graphManager.downloadAllIds()
        } catch let error as GraphStoreReadError{
            _graphStoreError = GraphStoreError.readError(error: error)
        } catch {
            logger.info("Unhandled exception downloading all IDs: \(error.localizedDescription)")
        }
        return []
    }
    
    func uploadGraphStoreNote(contents: NoteContents, metadata: NoteMeta) async {
        do {
            try await graphManager.uploadGraphStoreNote(contents: contents,
                                                        metadata: metadata)
        } catch let error as GraphStoreSaveError{
            _graphStoreError = GraphStoreError.saveError(error: error)
        } catch {
            logger.info("Unhandled exception uploading note: \(error.localizedDescription)")

        }
    }
}
