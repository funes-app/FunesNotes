import Foundation
import Combine
import UrsusHTTP
import SwiftGraphStore
import os

class NoteGraphManager: NoteGraphManaging {
    private let graphStoreInterface: GraphStoreAsyncInterfacing
    private let resource: Resource
    private let revisionManager: NoteGraphRevisionManaging

    @Published private var _graphStoreError: GraphStoreError?
    var graphStoreError: AnyPublisher<GraphStoreError, Never> {
        $_graphStoreError
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    @Published private var _graphSetupStatusChanged: GraphSetupStatus?
    var graphSetupStatusChanged: AnyPublisher<GraphSetupStatus, Never> {
        $_graphSetupStatusChanged
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    private let logger = Logger()
    
    convenience init(resource: Resource,
                     graphStoreInterface: GraphStoreAsyncInterfacing) {
        let revisionManager = NoteGraphRevisionManager(resource: resource,
                                                       graphStoreInterface: graphStoreInterface)
        self.init(resource: resource,
                  graphStoreInterface: graphStoreInterface,
                  revisionManager: revisionManager)
    }
    
    init(resource: Resource,
         graphStoreInterface: GraphStoreAsyncInterfacing,
         revisionManager: NoteGraphRevisionManaging) {
        self.graphStoreInterface = graphStoreInterface
        self.resource = resource
        self.revisionManager = revisionManager
        
        _graphSetupStatusChanged = .ready
    }
    
    func setupGraph() async throws {
        _graphSetupStatusChanged = .verifyingGraph
        let resourceState = try await revisionManager.getResourceState()
        
        if case .missingGraph = resourceState {
            _graphSetupStatusChanged = .creatingGraph
            try await createGraph()
            _graphSetupStatusChanged = .creatingRootNode
            try await createRootNode()
        } else if case .missingRootNode = resourceState {
            _graphSetupStatusChanged = .creatingRootNode
            try await createRootNode()
        }
        _graphSetupStatusChanged = .done
    }
    
    func downloadAllIds() async throws -> [NoteId] {
        logger.debug("Requesting children of root node")

        let index = GraphStoreIndex.rootNode.index
        let response = try await graphStoreInterface.readChildren(resource: resource,
                                                                index: index,
                                                                mode: .excludeDescendants)

        let update = response.graphUpdate
        
        guard case GraphUpdate.addNodes(_, let nodes) = update else {
            throw GraphStoreReadError.invalidResponse(update: update)
        }
        
        logger.debug("Here are the indices:")
        nodes.keys.forEach { logger.debug("\($0)") }
        
        return nodes.keys.compactMap { $0.noteId }
        
    }
    
    func getNoteStatus(_ keyPath: KeyPath<NoteMeta, Date>,
                       sourceMetadata: NoteMeta,
                       destinationMetadata: NoteMeta?) -> NoteGraphStatus {
        let sourceLastModified = sourceMetadata[keyPath: keyPath]
        let destinationLastModified = destinationMetadata?[keyPath: keyPath]
        return getStatus(sourceLastModified: sourceLastModified,
                         destinationLastModified: destinationLastModified)
    }
    
    private func getStatus(sourceLastModified: Date,
                           destinationLastModified: Date?) -> NoteGraphStatus {
        guard let destinationLastModified = destinationLastModified else {
            return .Missing
        }

        if destinationLastModified < sourceLastModified {
            return .OutOfDate
        } else if destinationLastModified > sourceLastModified{
            return .Newer(lastModified: destinationLastModified)
        } else {
            return .UpToDate
        }
    }

    func uploadGraphStoreNote(contents: NoteContents,
                              metadata: NoteMeta) async throws {
        try await uploadGraphStoreNote(contents: contents,
                                       metadata: metadata,
                                       noteGraphCreator: NoteGraphCreator())
    }

    internal func uploadGraphStoreNote(contents: NoteContents,
                                       metadata: NoteMeta,
                                       noteGraphCreator: NoteGraphCreating) async throws {
        let graphStoreMetadata: NoteMeta? = try await downloadLatestRevision(id: metadata.id)

        let contentsStatus = getNoteStatus(\.contentsLastModified,
                                            sourceMetadata: metadata,
                                            destinationMetadata: graphStoreMetadata)
        
        if case .Missing = contentsStatus {
            logger.debug("Note with id \(contents.id) is missing from graph store.  Creating...")
            try await createGraphStoreNote(contents: contents,
                                           metadata: metadata,
                                           noteGraphCreator: noteGraphCreator)
            return
        }
        
        try await uploadGraphStoreRevision(status: contentsStatus,
                                           revision: contents)
        
        let metadataStatus = getNoteStatus(\.metadataLastModified,
                                            sourceMetadata: metadata,
                                            destinationMetadata: graphStoreMetadata)
        
        try await uploadGraphStoreRevision(status: metadataStatus,
                                           revision: metadata)
    }
    
    internal func uploadGraphStoreRevision<T: GraphStoreRevisioning>(status: NoteGraphStatus,
                                                                 revision: T) async throws {
        switch status {
        case .OutOfDate:
            logger.debug("Note with id \(revision.id) is out of date. Updating...")
            try await updateGraphStoreRevision(revision: revision)
        case .UpToDate:
            logger.debug("Note with id \(revision.id) up to date.  No action needed.")
            return
        case .Newer(let lastModified):
            logger.debug("Note with id \(revision.id) has a newer version in graph store.  Throwing error")
            throw GraphStoreSaveError.graphStoreVersionIsNewer(graphStoreLastModified: lastModified)
        default:
            return
        }
    }
    
    func downloadGraphStoreNote(id: NoteId,
                                fileMetadata: NoteMeta?) async throws -> (contents: NoteContents?, metadata: NoteMeta?) {
        
        let graphStoreMetadata: NoteMeta? = try await downloadLatestRevision(id: id)
        
        guard let graphStoreMetadata = graphStoreMetadata else {
            return (nil, nil)
        }
        
        let contentsStatus = getNoteStatus(\.contentsLastModified,
                                            sourceMetadata: graphStoreMetadata,
                                            destinationMetadata: fileMetadata)
        
        if case .Missing = contentsStatus {
            let contents: NoteContents? = try await downloadLatestRevision(id: id)

            return (contents, graphStoreMetadata)
        }
        
        let contents: NoteContents? = try await downloadGraphStoreRevision(id: id,
                                                                           status: contentsStatus)

        let metadataStatus = getNoteStatus(\.metadataLastModified,
                                            sourceMetadata: graphStoreMetadata,
                                            destinationMetadata: fileMetadata)
        
        var metadata: NoteMeta?
        if case .OutOfDate = metadataStatus {
            metadata = graphStoreMetadata
        }
        
        return (contents, metadata)
    }
    
    
    internal func downloadGraphStoreRevision<T: GraphStoreRevisioning>(id: NoteId,
                                                                       status: NoteGraphStatus) async throws -> T? {
        switch status {
        case .OutOfDate:
            logger.debug("Note with id \(id) is out of date. Downloading...")
            return try await downloadLatestRevision(id: id)
        case .UpToDate:
            logger.debug("Note with id \(id) up to date.  No action needed.")
            return nil
        case .Newer:
            logger.debug("Note with id \(id) has a newer version in graph store.  Ignoring...")
            return nil
        default:
            logger.debug("Unexpected status trying to download.  Ignoring...")
            return nil
        }
    }
    
    func downloadLatestRevision<T: GraphStoreRevisioning>(id: NoteId) async throws -> T? {
        let revisionNumber: Atom
        do {
            revisionNumber = try await revisionManager.getLastRevisionNumber(type: T.self, id: id)
        } catch GraphStoreReadError.notFound {
            return nil
        }
        
        return try await revisionManager.getRevision(id: id,
                                                     revision: revisionNumber)
    }
        
    func createGraph() async throws {
        do {
            try await graphStoreInterface.createGraph(resource: resource)
        } catch let error as PokeError {
            throw GraphStoreSaveError.createGraphFailure(resource: resource,
                                                         error: error)
        }
    }
    
    private func createRootNode() async throws {
        let index = GraphStoreIndex.rootNode.index
        let post = Post(ship: resource.ship,
                        index: index)
        
        do {
            try await graphStoreInterface.addNode(resource: resource,
                                                  post: post,
                                                  children: nil)
        } catch let error as PokeError {
            throw GraphStoreSaveError.saveFailure(error: error)
        }
    }
    
    private func createGraphStoreNote(contents: NoteContents,
                                      metadata: NoteMeta,
                                      noteGraphCreator: NoteGraphCreating) async throws {
        let (post, children) = noteGraphCreator.newPostAndChildren(resource: resource,
                                                                   contents: contents,
                                                                   metadata: metadata)
        do {
            try await graphStoreInterface.addNode(resource: resource,
                                                  post: post,
                                                  children: children)
        } catch let error as PokeError {
            throw GraphStoreSaveError.saveFailure(error: error)
        }
    }
    
    private func updateGraphStoreRevision<T: GraphStoreRevisioning>(revision: T) async throws {
        let revisionNumber = try await revisionManager.getLastRevisionNumber(type: T.self, id: revision.id)
        
        try await revisionManager.saveRevision(revision: revision,
                                               revisionNumber: revisionNumber+1)
    }
    
    private func getPost(graphUpdate: GraphUpdate) throws -> Post {
        let nodes = try getNodes(graphUpdate: graphUpdate)
        
        guard let graph = nodes.values.first else {
            logger.info("Response nodes didn't have any values")
            throw GraphStoreReadError.invalidResponse(update: graphUpdate)
        }
        
        return graph.post
    }
    
    private func getNodes(graphUpdate: GraphUpdate) throws -> [Index: Node] {
        guard case let .addNodes(_, nodes) = graphUpdate else {
            logger.info("Ship did not return an 'addNodes' response!")
            throw GraphStoreReadError.invalidResponse(update: graphUpdate)
        }
        return nodes
    }
}
