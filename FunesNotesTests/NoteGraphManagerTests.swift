import XCTest
import UrsusHTTP
import SwiftGraphStore
import SwiftGraphStoreFakes
@testable import FunesNotes

class NoteGraphManagerTests: XCTestCase, ErrorVerifying {
    
    func test_setupGraph_asksForResourceState() async throws {
        let revisionManager = FakeNoteGraphRevisionManager()
        revisionManager.getResourceState_returnState = .testInstance
        
        let testObject = NoteGraphManager(resource: Resource.testInstance,
                                          graphStoreInterface: FakeGraphStoreAsyncInterface(),
                                          revisionManager: revisionManager)
        
        let _ = try await testObject.setupGraph()
        
        XCTAssertEqual(revisionManager.getResourceState_calledCount, 1)
    }
    
    func test_setupGraph_whenResourceStateFails_publishesReadError() async throws {
        let revisionManager = FakeNoteGraphRevisionManager()
        
        let testObject = NoteGraphManager(resource: Resource.testInstance,
                                          graphStoreInterface: FakeGraphStoreAsyncInterface(),
                                          revisionManager: revisionManager)
        
        let scryError = ScryError.testInstance
        let expectedError = GraphStoreReadError.readFailure(error: scryError)
        revisionManager.getResourceState_error = expectedError
        
        do {
            try await testObject.setupGraph()
        } catch let readError as GraphStoreReadError {
            verifyReadError(error: readError, scryError: scryError)
        }
    }
    
    func test_setupGraph_whenResourceConfigured_sendsConnectedStatus() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        let revisionManager = FakeNoteGraphRevisionManager()
        
        let testObject = NoteGraphManager(resource: Resource.testInstance,
                                          graphStoreInterface: graphStoreInterface,
                                          revisionManager: revisionManager)
        
        revisionManager.getResourceState_returnState = .configured
        
        try await testObject.setupGraph()
        
        let graphStatusPublisher = testObject
            .graphSetupStatusChanged
            .eraseToAnyPublisher()
        let graphSetupStatus = try await waitForResult(graphStatusPublisher)
        
        XCTAssertEqual(graphSetupStatus, .done)
        
        XCTAssertEqual(graphStoreInterface.createGraph_calledCount, 0)
        XCTAssertEqual(graphStoreInterface.addNode_calledCount, 0)
    }
    
    func test_setupGraph_whenRootNodeIsMissing_createsRootNode() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        let revisionManager = FakeNoteGraphRevisionManager()
        
        let testObject = NoteGraphManager(resource: Resource.testInstance,
                                          graphStoreInterface: graphStoreInterface,
                                          revisionManager: revisionManager)
        
        revisionManager.getResourceState_returnState = .missingRootNode
        
        try await testObject.setupGraph()
        
        XCTAssertEqual(graphStoreInterface.createGraph_calledCount, 0)
        XCTAssertEqual(graphStoreInterface.addNode_calledCount, 1)
    }
    
    func test_setupGraph_whenCreateRootNoteThrows_publishesSaveError() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        let revisionManager = FakeNoteGraphRevisionManager()
        
        let testObject = NoteGraphManager(resource: Resource.testInstance,
                                          graphStoreInterface: graphStoreInterface,
                                          revisionManager: revisionManager)
        
        revisionManager.getResourceState_returnState = .missingRootNode
        
        let pokeError = PokeError.testInstance
        graphStoreInterface.addNode_error = pokeError
        
        do {
            try await testObject.setupGraph()
        } catch let saveError as GraphStoreSaveError {
            verifySaveError(error: saveError, pokeError: pokeError)
        }
    }
    
    func test_setupGraph_whenGraphIsMissing_createsGraphAndRootNode() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        let revisionManager = FakeNoteGraphRevisionManager()
        
        let testObject = NoteGraphManager(resource: Resource.testInstance,
                                          graphStoreInterface: graphStoreInterface,
                                          revisionManager: revisionManager)
        
        revisionManager.getResourceState_returnState = .missingGraph
        
        try await testObject.setupGraph()
        
        XCTAssertEqual(graphStoreInterface.createGraph_calledCount, 1)
        XCTAssertEqual(graphStoreInterface.addNode_calledCount, 1)
    }
    
    func test_setupGraph_whenCreateGraphErrorThrown_publishes() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        let revisionManager = FakeNoteGraphRevisionManager()
        
        let resource = Resource.testInstance
        let testObject = NoteGraphManager(resource: resource,
                                          graphStoreInterface: graphStoreInterface,
                                          revisionManager: revisionManager)
        
        revisionManager.getResourceState_returnState = .missingGraph
        
        let pokeError = PokeError.testInstance
        graphStoreInterface.createGraph_error = pokeError
        
        do {
            try await testObject.setupGraph()
        } catch let saveError as GraphStoreSaveError {
            verifyCreateGraphFailure(error: saveError,
                                     resource: resource,
                                     pokeError: pokeError)
        }
    }
    
    func test_setupGraph_whenCreateNodeFails_convertsPokeError() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        let revisionManager = FakeNoteGraphRevisionManager()
        
        let testObject = NoteGraphManager(resource: Resource.testInstance,
                                          graphStoreInterface: graphStoreInterface,
                                          revisionManager: revisionManager)
        
        revisionManager.getResourceState_returnState = .missingRootNode
        
        let pokeError = PokeError.testInstance
        graphStoreInterface.addNode_error = pokeError
        
        do {
            try await testObject.setupGraph()
        } catch let saveError as GraphStoreSaveError {
            verifySaveError(error: saveError, pokeError: pokeError)
        }
    }
    
    func test_downloadLatestRevision_getsLastRevisionFromRevisionManager() async throws {
        let resource = Resource.testInstance
        let revisionManager = FakeNoteGraphRevisionManager()
        let testObject = NoteGraphManager(resource: resource,
                                          graphStoreInterface: FakeGraphStoreAsyncInterface(),
                                          revisionManager: revisionManager)
        
        revisionManager.getLastRevisionNumber_returnAtom = 0
        revisionManager.getRevision_returnRevision = [NoteContents.testInstance]
        
        let noteId = NoteId.testInstance
        let _: NoteContents? = try await testObject.downloadLatestRevision(id: noteId)
        
        XCTAssertEqual(revisionManager.getLastRevisionNumber_calledCount, 1)
        XCTAssert(revisionManager.getLastRevisionNumber_paramTypes.first is NoteContents.Type)
        XCTAssertEqual(revisionManager.getLastRevisionNumber_paramIds.first, noteId)
    }
    
    func test_downloadLatestRevision_whenLastRevisionNotFound_returnsNil() async throws {
        let resource = Resource.testInstance
        let revisionManager = FakeNoteGraphRevisionManager()
        
        let testObject = NoteGraphManager(resource: resource,
                                          graphStoreInterface: FakeGraphStoreAsyncInterface(),
                                          revisionManager: revisionManager)
        
        revisionManager.getLastRevisionNumber_error = GraphStoreReadError.notFound(resource: Resource.testInstance, index: Index.testInstance)
        
        let noteMeta: NoteMeta? = try await testObject.downloadLatestRevision(id: NoteId.testInstance)
        
        XCTAssertNil(noteMeta)
        XCTAssertEqual(revisionManager.getRevision_calledCount, 0)
    }
    
    func test_downloadLatestRevision_requestsHighestRevision() async throws {
        let revisionManager = FakeNoteGraphRevisionManager()
        
        revisionManager.getRevision_returnRevision = [NoteMeta.testInstance]
        
        let testObject = NoteGraphManager(resource: Resource.testInstance,
                                          graphStoreInterface: FakeGraphStoreAsyncInterface(),
                                          revisionManager: revisionManager)
        
        let noteId = NoteId.testInstance
        let revision: Atom = Atom.testInstance
        revisionManager.getLastRevisionNumber_returnAtom = revision
        
        let _: NoteMeta? = try await testObject.downloadLatestRevision(id: noteId)
        
        XCTAssertEqual(revisionManager.getRevision_calledCount, 1)
        XCTAssertEqual(revisionManager.getRevision_paramIds, [noteId])
        XCTAssertEqual(revisionManager.getRevision_paramRevisions, [revision])
    }
    
    func test_downloadLatestRevision_returnsRevisionFromRevisionManager() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        let revisionManager = FakeNoteGraphRevisionManager()
        revisionManager.getLastRevisionNumber_returnAtom = 0
        
        let testObject = NoteGraphManager(resource: Resource.testInstance,
                                          graphStoreInterface: graphStoreInterface,
                                          revisionManager: revisionManager)
        
        
        let expectedContents = NoteContents.testInstance
        revisionManager.getRevision_returnRevision = [expectedContents]
        
        let contents: NoteContents? = try await testObject.downloadLatestRevision(id: NoteId.testInstance)
        
        XCTAssertEqual(contents, expectedContents)
    }

    func test_getNoteStatus_whenGraphStoreRevisionIsNil_returnsMissing() async throws {
        let testObject = NoteGraphManager(resource: Resource.testInstance,
                                          graphStoreInterface: FakeGraphStoreAsyncInterface(),
                                          revisionManager: FakeNoteGraphRevisionManager())
        let status = testObject.getNoteStatus(\.metadataLastModified,
                                               sourceMetadata: NoteMeta.testInstance,
                                               destinationMetadata: nil)
        
        XCTAssertEqual(status, .Missing)
    }
    
    func test_getNoteStatus_ifGraphStoreContentsAreOlder_returnsOutOfDate() async throws {
        let testObject = NoteGraphManager(resource: Resource.testInstance,
                                          graphStoreInterface: FakeGraphStoreAsyncInterface(),
                                          revisionManager: FakeNoteGraphRevisionManager())
                
        let sourceMetadata = NoteMeta(NoteContents.testInstance,
                                      contentsLastModified: .now,
                                      metadataLastModified: .now)
        let destinationMetadata = NoteMeta(NoteContents.testInstance,
                                           contentsLastModified: .distantPast,
                                           metadataLastModified: .now)
        
        let status = testObject.getNoteStatus(\.contentsLastModified,
                                               sourceMetadata: sourceMetadata,
                                               destinationMetadata: destinationMetadata)
        
        XCTAssertEqual(status, NoteGraphStatus.OutOfDate)
    }
    
    func test_getNoteStatus_ifGraphStoreMetadataIsNewer_returnsNewer() async throws {
        let testObject = NoteGraphManager(resource: Resource.testInstance,
                                          graphStoreInterface: FakeGraphStoreAsyncInterface(),
                                          revisionManager: FakeNoteGraphRevisionManager())
        
        let sourceMetadata = NoteMeta(NoteContents.testInstance,
                                      contentsLastModified: .now,
                                      metadataLastModified: .now)
        let destinationMetadata = NoteMeta(NoteContents.testInstance,
                                           contentsLastModified: .distantFuture,
                                           metadataLastModified: .now)

        let status = testObject.getNoteStatus(\.contentsLastModified,
                                               sourceMetadata: sourceMetadata,
                                               destinationMetadata: destinationMetadata)
        
        XCTAssertEqual(status, NoteGraphStatus.Newer(lastModified: .distantFuture))
    }
    
    func test_getStatus_ifGraphStoreContentsAreSame_returnsUpToDate() {
        let testObject = NoteGraphManager(resource: .testInstance,
                                          graphStoreInterface: FakeGraphStoreAsyncInterface(),
                                          revisionManager: FakeNoteGraphRevisionManager())
        
        let modifiedTime = Date.now
        let destinationMetadata = NoteMeta(NoteContents.testInstance,
                                          contentsLastModified: modifiedTime,
                                          metadataLastModified: .now)
        
        let metadata = NoteMeta(NoteContents.testInstance,
                                contentsLastModified: modifiedTime,
                                metadataLastModified: .now)
        let contentsStatus = testObject.getNoteStatus(\.contentsLastModified,
                                                       sourceMetadata: metadata,
                                                       destinationMetadata: destinationMetadata)
        XCTAssertEqual(contentsStatus, NoteGraphStatus.UpToDate)
    }
    
    public func test_uploadGraphStoreNote_downloadsMetadata() async throws {
        let resource = Resource.testInstance
        let revisionManager = FakeNoteGraphRevisionManager()
        let testObject = NoteGraphManager(resource: resource,
                                          graphStoreInterface: FakeGraphStoreAsyncInterface(),
                                          revisionManager: revisionManager)
        
        setupForGraphDoesNotExist(revisionManager)
        
        let metadata = NoteMeta.testInstance
        let _ = try await testObject.uploadGraphStoreNote(contents: NoteContents.testInstance,
                                                          metadata: metadata)
        
        XCTAssertEqual(revisionManager.getLastRevisionNumber_calledCount, 1)
        XCTAssertEqual(revisionManager.getLastRevisionNumber_paramIds.first, metadata.id)
        XCTAssert(revisionManager.getLastRevisionNumber_paramTypes.first is NoteMeta.Type)
    }
    
    public func test_uploadGraphStoreNote_whenMetadataRevisionNumberFails_throws() async throws {
        let revisionManager = FakeNoteGraphRevisionManager()
        let resource = Resource.testInstance
        let testObject = NoteGraphManager(resource: resource,
                                          graphStoreInterface: FakeGraphStoreAsyncInterface(),
                                          revisionManager: revisionManager)
        
        let scryError = ScryError.testInstance
        revisionManager.getLastRevisionNumber_error = GraphStoreReadError.readFailure(error: scryError)
        
        let contents = NoteContents.testInstance
        
        do {
            let _ = try await testObject.uploadGraphStoreNote(contents: contents,
                                                              metadata: NoteMeta.testInstance)
        } catch let readError as GraphStoreReadError {
            verifyReadError(error: readError, scryError: scryError)
        }
    }
    
    func test_uploadGraphStoreNote_downloadMetadataFails_throws() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        let revisionManager = FakeNoteGraphRevisionManager()
        
        let testObject = NoteGraphManager(resource: Resource.testInstance,
                                          graphStoreInterface: graphStoreInterface,
                                          revisionManager: revisionManager)
        
        setupForGraphExists(graphStoreInterface, revisionManager)
        
        let scryError = ScryError.testInstance
        revisionManager.getRevision_error = GraphStoreReadError.readFailure(error: scryError)
        
        let revision = Atom.testInstance
        revisionManager.getLastRevisionNumber_returnAtom = revision
        
        let contents = NoteContents.testInstance
        do {
            try await testObject.uploadGraphStoreNote(contents: contents,
                                                      metadata: NoteMeta.testInstance)
        } catch let readError as GraphStoreReadError {
            verifyReadError(error: readError, scryError: scryError)
        }
        
        XCTAssertEqual(revisionManager.saveRevision_calledCount, 0)
    }
    
    func test_uploadGraphStoreNote_ifItemNotFound_createsIt() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        
        let resource = Resource.testInstance
        let revisionManager = FakeNoteGraphRevisionManager()
        let testObject = NoteGraphManager(resource: resource,
                                          graphStoreInterface: graphStoreInterface,
                                          revisionManager: revisionManager)
        
        setupForGraphDoesNotExist(revisionManager)
        
        let graphCreator = FakeNoteGraphCreator()
        
        let post = Post.testInstance
        let graph = Graph.testInstance
        graphCreator.newPostAndChildren_returnPost = post
        graphCreator.newPostAndChildren_returnGraph = graph
        
        let contents = NoteContents.testInstance
        let metadata = NoteMeta.testInstance
        try await testObject.uploadGraphStoreNote(contents: contents,
                                                  metadata: metadata,
                                                  noteGraphCreator: graphCreator)
        
        XCTAssertEqual(graphCreator.newPostAndChildren_calledCount, 1)
        XCTAssertEqual(graphCreator.newPostAndChildren_paramResource, resource)
        XCTAssertEqual(graphCreator.newPostAndChildren_paramContents, contents)
        XCTAssertEqual(graphCreator.newPostAndChildren_paramMetadata, metadata)
        XCTAssertEqual(graphStoreInterface.addNode_calledCount, 1)
        XCTAssertEqual(graphStoreInterface.addNode_paramPost, post)
        XCTAssertEqual(graphStoreInterface.addNode_paramChildren, graph)
    }
    
    func test_uploadGraphStoreNote_ifCreateNodeFails_throwsSaveError() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        let revisionManager = FakeNoteGraphRevisionManager()
        
        let testObject = NoteGraphManager(resource: Resource.testInstance,
                                          graphStoreInterface: graphStoreInterface,
                                          revisionManager: revisionManager)
        
        setupForGraphDoesNotExist(revisionManager)
        
        let pokeError = PokeError.testInstance
        graphStoreInterface.addNode_error = pokeError
        
        let contents = NoteContents.testInstance
        let metadata = NoteMeta.testInstance
        
        do {
            try await testObject.uploadGraphStoreNote(contents: contents,
                                                      metadata: metadata)
        } catch let saveError as GraphStoreSaveError {
            verifySaveError(error: saveError, pokeError: pokeError)
        }
    }
    
    func test_uploadGraphStoreNote_ifGraphStoreContentsAreOlder_savesContents() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        let revisionManager = FakeNoteGraphRevisionManager()
        
        let testObject = NoteGraphManager(resource: Resource.testInstance,
                                          graphStoreInterface: graphStoreInterface,
                                          revisionManager: revisionManager)
        
        setupForGraphExists(graphStoreInterface, revisionManager)
        
        let modifiedTime = Date.now
        let returnedNoteMeta = NoteMeta(NoteContents.testInstance,
                                        contentsLastModified: .distantPast,
                                        metadataLastModified: modifiedTime)
        revisionManager.getRevision_returnRevision = [returnedNoteMeta]
        
        let contents = NoteContents.testInstance
        let metadata = NoteMeta(NoteContents.testInstance,
                                contentsLastModified: .now,
                                metadataLastModified: modifiedTime)
        try await testObject.uploadGraphStoreNote(contents: contents,
                                                  metadata: metadata)
        
        XCTAssertEqual(revisionManager.saveRevision_calledCount, 1)
        let paramRevisions = revisionManager.saveRevision_paramRevisions
        XCTAssertEqual(paramRevisions.count, 1)
        XCTAssertEqual(paramRevisions[0].id, contents.id)
    }
    
    func test_uploadGraphStoreNote_ifSaveFails_throwsSaveError() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        let revisionManager = FakeNoteGraphRevisionManager()
        
        let testObject = NoteGraphManager(resource: Resource.testInstance,
                                          graphStoreInterface: graphStoreInterface,
                                          revisionManager: revisionManager)
        
        setupForGraphExists(graphStoreInterface, revisionManager)
        setupForOldContents(revisionManager, .now)
        
        let pokeError = PokeError.testInstance
        revisionManager.saveRevision_error = GraphStoreSaveError.saveFailure(error: pokeError)
        
        let metadata = NoteMeta(NoteContents.testInstance,
                                contentsLastModified: .now,
                                metadataLastModified: .now)
        
        do {
            try await testObject.uploadGraphStoreNote(contents: .testInstance,
                                                      metadata: metadata)
        } catch let saveError as GraphStoreSaveError {
            verifySaveError(error: saveError, pokeError: pokeError)
        }
    }
    
    func test_uploadGraphStoreNote_ifGraphStoreContentsAndMetadataAreSameDate_doesNotSave() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        let revisionManager = FakeNoteGraphRevisionManager()
        
        let testObject = NoteGraphManager(resource: .testInstance,
                                          graphStoreInterface: graphStoreInterface,
                                          revisionManager: revisionManager)
        
        setupForGraphExists(graphStoreInterface, revisionManager)
        
        let modifiedTime = Date.now
        let returnedNoteMeta = NoteMeta(NoteContents.testInstance,
                                        contentsLastModified: modifiedTime,
                                        metadataLastModified: modifiedTime)
        revisionManager.getRevision_returnRevision = [returnedNoteMeta]
        
        let metadata = NoteMeta(NoteContents.testInstance,
                                contentsLastModified: modifiedTime,
                                metadataLastModified: modifiedTime)
        do {
            try await testObject.uploadGraphStoreNote(contents: .testInstance,
                                                      metadata: metadata)
        } catch {
            XCTFail("Should not have thrown here")
        }
        
        XCTAssertEqual(revisionManager.saveRevision_calledCount, 0)
    }
    
    func test_uploadGraphStoreNote_ifGraphStoreContentsAreNewer_throws() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        let revisionManager = FakeNoteGraphRevisionManager()
        
        let testObject = NoteGraphManager(resource: .testInstance,
                                          graphStoreInterface: graphStoreInterface,
                                          revisionManager: revisionManager)
        
        setupForGraphExists(graphStoreInterface, revisionManager)
        setupForNewContents(revisionManager, .now)
        
        let metadata = NoteMeta(NoteContents.testInstance,
                                contentsLastModified: .now,
                                metadataLastModified: .now)
        do {
            try await testObject.uploadGraphStoreNote(contents: .testInstance,
                                                      metadata: metadata)
        } catch GraphStoreSaveError.graphStoreVersionIsNewer(let errorLastModified) {
            XCTAssertEqual(errorLastModified, Date.distantFuture)
        }
    }
    
    func test_uploadGraphStoreNote_ifGraphStoreMetadataIsOlder_saves() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        let revisionManager = FakeNoteGraphRevisionManager()
        
        let testObject = NoteGraphManager(resource: .testInstance,
                                          graphStoreInterface: graphStoreInterface,
                                          revisionManager: revisionManager)
        
        setupForGraphExists(graphStoreInterface, revisionManager)
        
        let modifiedTime = Date.now
        setupForOldMetadata(revisionManager, modifiedTime)
        
        let metadata = NoteMeta(NoteContents.testInstance,
                                contentsLastModified: modifiedTime,
                                metadataLastModified: modifiedTime)
        do {
            try await testObject.uploadGraphStoreNote(contents: .testInstance,
                                                      metadata: metadata)
        } catch {
            XCTFail("Should not have thrown here")
        }
        
        XCTAssertEqual(revisionManager.saveRevision_calledCount, 1)
    }
    
    func test_uploadGraphStoreNote_ifMetadataIsNewer_throws() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        let revisionManager = FakeNoteGraphRevisionManager()
        
        let testObject = NoteGraphManager(resource: .testInstance,
                                          graphStoreInterface: graphStoreInterface,
                                          revisionManager: revisionManager)
        
        setupForGraphExists(graphStoreInterface, revisionManager)
        
        let modified = Date.now
        setupForNewMetadata(revisionManager, modified)
        
        let metadata = NoteMeta(NoteContents.testInstance,
                                contentsLastModified: modified,
                                metadataLastModified: .now)
        do {
            try await testObject.uploadGraphStoreNote(contents: .testInstance,
                                                      metadata: metadata)
        } catch GraphStoreSaveError.graphStoreVersionIsNewer(let errorLastModified) {
            XCTAssertEqual(errorLastModified, Date.distantFuture)
        }
    }
    func test_downloadAllIds_requestsChildrenOfRootNode() async throws {
        let resource = Resource.testInstance
        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        
        let testObject = NoteGraphManager(resource: resource,
                                          graphStoreInterface: graphStoreInterface,
                                          revisionManager: FakeNoteGraphRevisionManager())
        
        graphStoreInterface.readChildren_returnUpdate = GraphStoreUpdate.testInstance
        
        let _ = try await testObject.downloadAllIds()
        
        XCTAssertEqual(graphStoreInterface.readChildren_calledCount, 1)
        XCTAssertEqual(graphStoreInterface.readChildren_paramResource, resource)
        let expectedIndex = GraphStoreIndex.rootNode.index
        XCTAssertEqual(graphStoreInterface.readChildren_paramIndex, expectedIndex)
        XCTAssertEqual(graphStoreInterface.readChildren_paramMode, .excludeDescendants)
    }
    
    
    func test_downloadAllIds_extractsIdsFromIndices() async throws {
        let resource = Resource.testInstance
        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        
        let testObject = NoteGraphManager(resource: resource,
                                          graphStoreInterface: graphStoreInterface,
                                          revisionManager: FakeNoteGraphRevisionManager())
        
        let expectedNoteIds = (0...5).map { _ in NoteId.testInstance }
        let atomArrays = expectedNoteIds.map {
            [Atom.testInstance, Atom(stringLiteral: $0.rawValue)]
        }
        let indices = atomArrays.map { Index(atoms: $0) }
        let nodeTuples = indices.map { ($0, Node.testInstance) }
        let nodes = Dictionary(uniqueKeysWithValues: nodeTuples)
        let graphUpdate = GraphUpdate.addNodes(resource: resource,
                                               nodes: nodes)
        graphStoreInterface.readChildren_returnUpdate = GraphStoreUpdate(graphUpdate: graphUpdate)
        
        let noteIds = try await testObject.downloadAllIds()
        
        XCTAssertEqual(noteIds.sorted(), expectedNoteIds.sorted())
    }
    
    func test_downloadGraphStoreNote_whenFileMetadataIsNull_downloadsContentsAndMetadata() async throws {
        
        let revisionManager = FakeNoteGraphRevisionManager()
        let testObject = NoteGraphManager(resource: Resource.testInstance,
                                          graphStoreInterface: FakeGraphStoreAsyncInterface(),
                                          revisionManager: revisionManager)
        
        revisionManager.getLastRevisionNumber_returnAtom = Atom.testInstance
        
        let expectedContents = NoteContents.testInstance
        let expectedMetadata = NoteMeta.testInstance
        revisionManager.getRevision_returnRevision = [expectedMetadata, expectedContents]
        
        let noteId = NoteId.testInstance
        let (contents, metadata) = try await testObject.downloadGraphStoreNote(id: noteId, fileMetadata: nil)
        
        XCTAssertEqual(revisionManager.getLastRevisionNumber_calledCount, 2)
        XCTAssertEqual(revisionManager.getRevision_paramIds, [noteId, noteId])
        
        XCTAssertEqual(contents, expectedContents)
        XCTAssertEqual(metadata, expectedMetadata)
    }
    
    func test_downloadGraphStoreNote_whenGraphContentsAreNewer_downloadsContents() async throws {
        
        let revisionManager = FakeNoteGraphRevisionManager()
        let testObject = NoteGraphManager(resource: Resource.testInstance,
                                          graphStoreInterface: FakeGraphStoreAsyncInterface(),
                                          revisionManager: revisionManager)
        
        revisionManager.getLastRevisionNumber_returnAtom = Atom.testInstance
        
        let modifiedTime = Date.now
        let expectedContents = NoteContents.testInstance
        let graphStoreMetadata = NoteMeta(NoteContents.testInstance,
                                          contentsLastModified: modifiedTime,
                                          metadataLastModified: modifiedTime)
        revisionManager.getRevision_returnRevision = [graphStoreMetadata, expectedContents]
        
        let noteId = NoteId.testInstance
        let fileMetadata = NoteMeta(NoteContents.testInstance,
                                    contentsLastModified: .distantPast,
                                    metadataLastModified: .distantPast)
        let (contents, _) = try await testObject.downloadGraphStoreNote(id: noteId, fileMetadata: fileMetadata)
        
        XCTAssertEqual(revisionManager.getLastRevisionNumber_calledCount, 2)
        XCTAssertEqual(revisionManager.getRevision_paramIds, [noteId, noteId])
        
        XCTAssertEqual(contents, expectedContents)
    }
    
    func test_downloadGraphStoreNote_whenGraphContentsAreTheSameAge_doesNotDownloadAndReturnsNil() async throws {
        
        let revisionManager = FakeNoteGraphRevisionManager()
        let testObject = NoteGraphManager(resource: Resource.testInstance,
                                          graphStoreInterface: FakeGraphStoreAsyncInterface(),
                                          revisionManager: revisionManager)
        
        revisionManager.getLastRevisionNumber_returnAtom = Atom.testInstance
        
        let modifiedTime = Date.now
        let expectedContents = NoteContents.testInstance
        let graphStoreMetadata = NoteMeta(NoteContents.testInstance,
                                          contentsLastModified: modifiedTime,
                                          metadataLastModified: modifiedTime)
        revisionManager.getRevision_returnRevision = [graphStoreMetadata, expectedContents]
        
        let noteId = NoteId.testInstance
        let fileMetadata = NoteMeta(NoteContents.testInstance,
                                    contentsLastModified: modifiedTime,
                                    metadataLastModified: modifiedTime)
        let (contents, _) = try await testObject.downloadGraphStoreNote(id: noteId, fileMetadata: fileMetadata)
        
        XCTAssertEqual(revisionManager.getLastRevisionNumber_calledCount, 1)
        XCTAssertEqual(revisionManager.getRevision_paramIds, [noteId])
        
        XCTAssertEqual(contents, nil)
    }
    
    func test_downloadGraphStoreNote_whenGraphStoreMetadataIsNewer_returnsGraphMetadata() async throws {
        
        let revisionManager = FakeNoteGraphRevisionManager()
        let testObject = NoteGraphManager(resource: Resource.testInstance,
                                          graphStoreInterface: FakeGraphStoreAsyncInterface(),
                                          revisionManager: revisionManager)
        
        revisionManager.getLastRevisionNumber_returnAtom = Atom.testInstance
        
        let modifiedTime = Date.now
        let expectedContents = NoteContents.testInstance
        let graphStoreMetadata = NoteMeta(NoteContents.testInstance,
                                          contentsLastModified: modifiedTime,
                                          metadataLastModified: .distantFuture)
        revisionManager.getRevision_returnRevision = [graphStoreMetadata, expectedContents]
        
        let noteId = NoteId.testInstance
        let fileMetadata = NoteMeta(NoteContents.testInstance,
                                    contentsLastModified: .distantPast,
                                    metadataLastModified: .now)
        let (_, metadata) = try await testObject.downloadGraphStoreNote(id: noteId, fileMetadata: fileMetadata)
        
        
        XCTAssertEqual(metadata, graphStoreMetadata)
    }
    
    func test_downloadGraphStoreNote_whenGraphMetadataIsTheSameAge_returnsNil() async throws {
        
        let revisionManager = FakeNoteGraphRevisionManager()
        let testObject = NoteGraphManager(resource: Resource.testInstance,
                                          graphStoreInterface: FakeGraphStoreAsyncInterface(),
                                          revisionManager: revisionManager)
        
        revisionManager.getLastRevisionNumber_returnAtom = Atom.testInstance
        
        let modifiedTime = Date.now
        let expectedContents = NoteContents.testInstance
        let graphStoreMetadata = NoteMeta(NoteContents.testInstance,
                                          contentsLastModified: modifiedTime,
                                          metadataLastModified: modifiedTime)
        revisionManager.getRevision_returnRevision = [graphStoreMetadata, expectedContents]
        
        let noteId = NoteId.testInstance
        let fileMetadata = NoteMeta(NoteContents.testInstance,
                                    contentsLastModified: modifiedTime,
                                    metadataLastModified: modifiedTime)
        let (_, metadata) = try await testObject.downloadGraphStoreNote(id: noteId, fileMetadata: fileMetadata)
        
        XCTAssertEqual(revisionManager.getLastRevisionNumber_calledCount, 1)
        XCTAssertEqual(revisionManager.getRevision_paramIds, [noteId])
        
        XCTAssertEqual(metadata, nil)
    }
    
    fileprivate func setupForGraphDoesNotExist(_ revisionManager: FakeNoteGraphRevisionManager) {
        revisionManager.getLastRevisionNumber_error = GraphStoreReadError.notFound(resource: Resource.testInstance, index: Index.testInstance)
    }
    
    fileprivate func setupForOldContents(_ revisionManager: FakeNoteGraphRevisionManager,
                                         _ metadataLastModified: Date) {
        let returnedNoteMeta = NoteMeta(NoteContents.testInstance,
                                        contentsLastModified: .distantPast,
                                        metadataLastModified: metadataLastModified)
        revisionManager.getRevision_returnRevision = [returnedNoteMeta]
    }
    
    fileprivate func setupForOldMetadata(_ revisionManager: FakeNoteGraphRevisionManager,
                                         _ contentsLastModified: Date) {
        let returnedNoteMeta = NoteMeta(NoteContents.testInstance,
                                        contentsLastModified: contentsLastModified,
                                        metadataLastModified: .distantPast)
        revisionManager.getRevision_returnRevision = [returnedNoteMeta]
    }
    
    fileprivate func setupForNewContents(_ revisionManager: FakeNoteGraphRevisionManager,
                                         _ metadataLastModified: Date) {
        let returnedNoteMeta = NoteMeta(NoteContents.testInstance,
                                        contentsLastModified: .distantFuture,
                                        metadataLastModified: metadataLastModified)
        revisionManager.getRevision_returnRevision = [returnedNoteMeta]
    }
    
    fileprivate func setupForNewMetadata(_ revisionManager: FakeNoteGraphRevisionManager,
                                         _ contentsLastModified: Date) {
        let returnedNoteMeta = NoteMeta(NoteContents.testInstance,
                                        contentsLastModified: contentsLastModified,
                                        metadataLastModified: .distantFuture)
        revisionManager.getRevision_returnRevision = [returnedNoteMeta]
    }
    
    fileprivate func setupForGraphExists(_ graphStoreInterface: FakeGraphStoreAsyncInterface,
                                         _ revisionManager: FakeNoteGraphRevisionManager) {
        let graphUpdate = GraphUpdate.addNodesWithEmptyRoot(resource: Resource.testInstance)
        graphStoreInterface.readNode_returnUpdate = GraphStoreUpdate(graphUpdate: graphUpdate)
        revisionManager.getLastRevisionNumber_returnAtom = Atom.testInstance
        revisionManager.getRevision_returnRevision = [NoteMeta.testInstance]
    }
}
