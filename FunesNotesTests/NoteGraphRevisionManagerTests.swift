import XCTest
import UrsusHTTP
import SwiftGraphStore
@testable import FunesNotes

class NoteGraphRevisionManagerTests: XCTestCase, ErrorVerifying {
    
    func test_getResourceState_readsRootNodes() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        let resource = Resource.testInstance
        
        let testObject = NoteGraphRevisionManager(resource: resource,
                                                  graphStoreInterface: graphStoreInterface)

        let graphUpdate = GraphUpdate.addNodesWithEmptyRoot(resource: resource)
        graphStoreInterface.readRootNodes_returnUpdate = GraphStoreUpdate(graphUpdate: graphUpdate)

        let _ = try await testObject.getResourceState()
        
        XCTAssertEqual(graphStoreInterface.readRootNodes_calledCount, 1)
        XCTAssertEqual(graphStoreInterface.readRootNodes_paramResource, resource)
    }
    
    func test_getResourceState_whenRootNodeExists_returnsConfigured() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()

        let testObject = NoteGraphRevisionManager(resource: Resource.testInstance,
                                                  graphStoreInterface: graphStoreInterface)

        let graphUpdate = GraphUpdate.addNodesWithEmptyRoot(resource: Resource.testInstance)
        graphStoreInterface.readRootNodes_returnUpdate = GraphStoreUpdate(graphUpdate: graphUpdate)

        let status = try await testObject.getResourceState()

        XCTAssertEqual(status, .configured)
    }

    func test_getResourceState_whenRootNodeIsMissing_returnsMissingRootNode() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()

        let testObject = NoteGraphRevisionManager(resource: Resource.testInstance,
                                                  graphStoreInterface: graphStoreInterface)

        let graphUpdate = GraphUpdate.emptyAddNodes(resource: Resource.testInstance)
        graphStoreInterface.readRootNodes_returnUpdate = GraphStoreUpdate(graphUpdate: graphUpdate)

        let status = try await testObject.getResourceState()

        XCTAssertEqual(status, .missingRootNode)
    }

    func test_getResourceState_whenGraphIsMissing_returnsMissingGraph() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()

        let testObject = NoteGraphRevisionManager(resource: Resource.testInstance,
                                                  graphStoreInterface: graphStoreInterface)

        let scryError = ScryError.resourceNotFound(url: nil)
        graphStoreInterface.readRootNodes_error = scryError

        let status = try await testObject.getResourceState()

        XCTAssertEqual(status, .missingGraph)
    }

    func test_getResourceState_whenReturnIsNotAddNodes_throws() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()

        let testObject = NoteGraphRevisionManager(resource: Resource.testInstance,
                                                  graphStoreInterface: graphStoreInterface)

        let graphUpdate = GraphUpdate.addGraph(resource: Resource.testInstance,
                                               graph: [:],
                                               mark: nil,
                                               overwrite: false)
        graphStoreInterface.readRootNodes_returnUpdate = GraphStoreUpdate(graphUpdate: graphUpdate)

        let expectedError = GraphStoreReadError.invalidResponse(update: graphUpdate)

        let action = {
            let _ = try await testObject.getResourceState()
        }
        try await verifyAsyncErrorThrown(action: action) { error in
            XCTAssertEqual(error.localizedDescription,
                           expectedError.localizedDescription)
        }
    }

    func test_getResourceState_whenReadFails_throws() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()

        let testObject = NoteGraphRevisionManager(resource: Resource.testInstance,
                                                  graphStoreInterface: graphStoreInterface)

        let scryError = ScryError.testInstance
        graphStoreInterface.readRootNodes_error = scryError

        let action = {
            let _ = try await testObject.getResourceState()
        }
        try await verifyAsyncErrorThrown(action: action) { error in
            verifyReadError(error: error, scryError: scryError)
        }
    }
    
    func test_getLastRevisionNumber_readsChildren() async throws {
        let resource = Resource.testInstance
        
        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        graphStoreInterface.readChildren_returnUpdate = updateForRevisionContainer()

        let testObject = NoteGraphRevisionManager(resource: resource, graphStoreInterface: graphStoreInterface)
        
        let noteId = NoteId.testInstance
        let _ = try await testObject.getLastRevisionNumber(type: NoteMeta.self, id: noteId)
        
        let expectedIndex = GraphStoreIndex
            .noteMetadataContainer(id: noteId)
            .index
        XCTAssertEqual(graphStoreInterface.readChildren_calledCount, 1)
        XCTAssertEqual(graphStoreInterface.readChildren_paramResource, resource)
        XCTAssertEqual(graphStoreInterface.readChildren_paramIndex, expectedIndex)
        XCTAssertEqual(graphStoreInterface.readChildren_paramMode, .excludeDescendants)
    }
    
    func test_getLastRevisionNumber_whenReadChildrenFails_convertsError() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        
        let testObject = NoteGraphRevisionManager(resource: Resource.testInstance, graphStoreInterface: graphStoreInterface)
        let scryError = ScryError.testInstance
        graphStoreInterface.readChildren_error = scryError
        
        let action = {
            let _ = try await testObject.getLastRevisionNumber(type: NoteMeta.self, id: NoteId.testInstance)
        }
        try await verifyAsyncErrorThrown(action: action) { error in
            verifyReadError(error: error, scryError: scryError)
        }
    }
    
    func test_getLastRevisionNumber_whenReadChildrenNotFound_throwsNotFound() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        
        let testObject = NoteGraphRevisionManager(resource: Resource.testInstance, graphStoreInterface: graphStoreInterface)
        
        let scryError = ScryError.resourceNotFound(url: nil)
        graphStoreInterface.readChildren_error = scryError
        
        let action = {
            let _ = try await testObject.getLastRevisionNumber(type: NoteMeta.self, id: NoteId.testInstance)
        }
        
        try await verifyAsyncErrorThrown(action: action,
                                         verifyError: verifyNotFound)
    }
    
    func test_getLastRevisionNumber_whenNoChildrenReturned_throws() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        
        let testObject = NoteGraphRevisionManager(resource: Resource.testInstance, graphStoreInterface: graphStoreInterface)
        
        let nodes = [Index: Node]()
        let graphUpdate = GraphUpdate.addNodes(resource: Resource.testInstance,
                                               nodes: nodes)
        
        graphStoreInterface.readChildren_returnUpdate = GraphStoreUpdate(graphUpdate: graphUpdate)
                
        let action = {
            let _ = try await testObject.getLastRevisionNumber(type: NoteMeta.self, id: NoteId.testInstance)
        }
        try await verifyAsyncErrorThrown(action: action,
                                         verifyError: verifyInvalidResponse)
    }
    
    func test_getLastRevisionNumber_returnsHighestRevisionNumber() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        
        let testObject = NoteGraphRevisionManager(resource: Resource.testInstance, graphStoreInterface: graphStoreInterface)

        let noteId = NoteId.testInstance
        let biggestRevision: Atom = 1000
        let revisions: [Atom] = (Array(0...10) + [biggestRevision]).shuffled()
        let indices = revisions.map { revision in
            GraphStoreIndex
                .noteMetadataRevisionContainer(id: noteId, revision: revision)
                .index
        }
        
        var nodes = [Index: Node]()
        indices.forEach { index in
            nodes[index] = Node(post: Post.testInstance, children: nil)
        }
        let graphUpdate = GraphUpdate.addNodes(resource: Resource.testInstance,
                                               nodes: nodes)
        
        graphStoreInterface.readChildren_returnUpdate = GraphStoreUpdate(graphUpdate: graphUpdate)
        
        let lastRevision = try await testObject.getLastRevisionNumber(type: NoteMeta.self, id: noteId)

        XCTAssertEqual(lastRevision, biggestRevision)
    }
    
    func test_getRevision_readsNodeFromRevision() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        let resource = Resource.testInstance
        
        let graphUpdate = GraphUpdate.updateForRevision(NoteContents.testInstance)
        graphStoreInterface.readNode_returnUpdate = GraphStoreUpdate(graphUpdate: graphUpdate)

        let testObject = NoteGraphRevisionManager(resource: resource, graphStoreInterface: graphStoreInterface)

        let noteId = NoteId.testInstance
        let revision: Atom = Atom.testInstance
        
        let _: NoteContents = try await testObject.getRevision(id: noteId,
                                                       revision: revision)
        
        let expectedIndex = GraphStoreIndex
            .noteContentsRevision(id: noteId, revision: revision)
            .index
        XCTAssertEqual(graphStoreInterface.readNode_calledCount, 1)
        XCTAssertEqual(graphStoreInterface.readNode_paramResource, resource)
        XCTAssertEqual(graphStoreInterface.readNode_paramIndex, expectedIndex)
        XCTAssertEqual(graphStoreInterface.readNode_paramMode, .includeDescendants)
    }
    
    func test_getRevision_whenNoNodeForRevisionFound_throws() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        
        let testObject = NoteGraphRevisionManager(resource: Resource.testInstance, graphStoreInterface: graphStoreInterface)

        let graphUpdate = GraphUpdate.addNodes(resource: Resource.testInstance,
                                               nodes: [:])
        graphStoreInterface.readNode_returnUpdate = GraphStoreUpdate(graphUpdate: graphUpdate)
        
        let action = {
            let _: NoteContents = try await testObject.getRevision(id: NoteId.testInstance,
                                                     revision: Atom.testInstance)
        }
        try await verifyAsyncErrorThrown(action: action, verifyError: verifyInvalidResponse)
    }

    func test_getRevision_whenReadNodeNotFound_throwsNotFound() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()

        let testObject = NoteGraphRevisionManager(resource: Resource.testInstance, graphStoreInterface: graphStoreInterface)

        let scryError = ScryError.resourceNotFound(url: nil)
        graphStoreInterface.readNode_error = scryError

        let action = {
            let _: NoteMeta = try await testObject.getRevision(id: NoteId.testInstance,
                                                     revision: Atom.testInstance)
        }
        try await verifyAsyncErrorThrown(action: action,
                                         verifyError: verifyNotFound)
    }
    
    func test_getRevision_whenReadNodeFails_convertsError() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        
        let testObject = NoteGraphRevisionManager(resource: Resource.testInstance, graphStoreInterface: graphStoreInterface)
                
        let scryError = ScryError.testInstance
        graphStoreInterface.readNode_error = scryError
        
        let action = {
            let _: NoteContents = try await testObject.getRevision(id: NoteId.testInstance,
                                                     revision: Atom.testInstance)
        }
        try await verifyAsyncErrorThrown(action: action) { error in
            verifyReadError(error: error, scryError: scryError)
        }
    }
    
    func test_getRevision_returnsConvertedPost() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        
        let testObject = NoteGraphRevisionManager(resource: Resource.testInstance, graphStoreInterface: graphStoreInterface)
        
        let expectedContents = NoteContents.testInstance
        let graphUpdate = GraphUpdate.updateForRevision(expectedContents)
        graphStoreInterface.readNode_returnUpdate = GraphStoreUpdate(graphUpdate: graphUpdate)

        let contents: NoteContents = try await testObject.getRevision(id: NoteId.testInstance,
                                                          revision: Atom.testInstance)

        XCTAssertEqual(contents, expectedContents)
    }
    
    func test_getRevision_canCreateMetadata() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        
        let testObject = NoteGraphRevisionManager(resource: Resource.testInstance, graphStoreInterface: graphStoreInterface)
        
        let returnedMetadata = NoteMeta.testInstance
        let graphUpdate = GraphUpdate.updateForRevision(returnedMetadata)
        graphStoreInterface.readNode_returnUpdate = GraphStoreUpdate(graphUpdate: graphUpdate)

        let id = NoteId.testInstance
        let metadata: NoteMeta = try await testObject.getRevision(id: id,
                                                                  revision: Atom.testInstance)

        XCTAssertEqual(metadata, returnedMetadata.withoutText)
    }
    
    func test_getRevision_whenPostContentsAreInvalid_throws() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        
        let testObject = NoteGraphRevisionManager(resource: Resource.testInstance, graphStoreInterface: graphStoreInterface)

        let graphUpdate = GraphUpdate.updateForRevision(NoteContents.testInstance)
        graphStoreInterface.readNode_returnUpdate = GraphStoreUpdate(graphUpdate: graphUpdate)
        
        let action = {
            let _: NoteMeta = try await testObject.getRevision(id: NoteId.testInstance,
                                                               revision: Atom.testInstance)
        }
        try await verifyAsyncErrorThrown(action: action, verifyError: verifyInvalidResponse)
    }
    
    func test_saveRevision_callsInterface() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        
        let resource = Resource.testInstance
        let testObject = NoteGraphRevisionManager(resource: resource, graphStoreInterface: graphStoreInterface)

        let revisionNumber = Atom.testInstance
        let contents = NoteContents.testInstance
        
        try await testObject.saveRevision(revision: contents, revisionNumber: revisionNumber)
        
        let expectedIndex = NoteContents.revisionContainerIndex(id: contents.id, revision: revisionNumber)
        let expectedPost = Post(ship: resource.ship, index: expectedIndex)
        
        let expectedGraph = contents.makeRevisionGraph(ship: resource.ship, revision: revisionNumber)
        XCTAssertEqual(graphStoreInterface.addNode_calledCount, 1)
        XCTAssertEqual(graphStoreInterface.addNode_paramResource, resource)
        XCTAssertEqualPosts(graphStoreInterface.addNode_paramPost, expectedPost)
        XCTAssertEqual(graphStoreInterface.addNode_paramChildren?.keys,
                       expectedGraph.keys)
    }
    
    func test_saveRevision_whenAddNodeFails_convertsError() async throws {
        let graphStoreInterface = FakeGraphStoreAsyncInterface()
        
        let testObject = NoteGraphRevisionManager(resource: Resource.testInstance, graphStoreInterface: graphStoreInterface)
                
        let pokeError = PokeError.testInstance
        graphStoreInterface.addNode_error = pokeError
        
        let action = {
            try await testObject.saveRevision(revision: NoteMeta.testInstance,
                                              revisionNumber: Atom.testInstance)
        }
        try await verifyAsyncErrorThrown(action: action) { error in
            verifySaveError(error: error, pokeError: pokeError)
        }
    }

    private func updateForRevisionContainer() -> GraphStoreUpdate {
        let index = GraphStoreIndex
            .noteMetadataRevisionContainer(id: NoteId.testInstance, revision: 1)
            .index
        
        let revisionsNodes = [index: Node(post: Post.testInstance, children: nil)]
        let revisionsUpdate = GraphUpdate.addNodes(resource: Resource.testInstance,
                                                   nodes: revisionsNodes)
        return GraphStoreUpdate(graphUpdate: revisionsUpdate)
    }
}
