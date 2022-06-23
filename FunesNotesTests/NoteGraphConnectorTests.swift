import XCTest
import SwiftGraphStore
import UrsusHTTP
@testable import FunesNotes

class NoteGraphConnectorTests: XCTestCase {
    func test_init_passesAlongStatusChanges() async throws {
        let graphManager = FakeNoteGraphManager()
        let testObject = NoteGraphConnector(graphManager: graphManager)
        
        let expectedStatus = GraphSetupStatus.creatingGraph
        graphManager._graphSetupStatusChanged = expectedStatus
        
        let status = try await waitForResult(testObject.graphSetupStatusChanged)
        
        XCTAssertEqual(status, expectedStatus)
    }
    
    func test_setupGraph_callsGraphManager() async {
        let graphManager = FakeNoteGraphManager()
        let testObject = NoteGraphConnector(graphManager: graphManager)
        
        await testObject.setupGraph()
        
        XCTAssertEqual(graphManager.setupGraph_calledCount, 1)
    }
    
    func test_setupGraph_whenGraphManagerThrows_publishesError() async throws {
        let graphManager = FakeNoteGraphManager()
        let testObject = NoteGraphConnector(graphManager: graphManager)

        let expectedSaveError = GraphStoreSaveError
            .saveFailure(error: PokeError.testInstance)
        let graphStoreError = GraphStoreError.saveError(error: expectedSaveError)
        graphManager.setupGraph_error = graphStoreError

        await testObject.setupGraph()

        let error = try await waitForResult(testObject.graphStoreError)
        
        guard case GraphStoreError.saveError(let saveError) = error else {
            XCTFail("Unexpected error: \(error.localizedDescription)")
            return
        }
        
        XCTAssertEqual(saveError.localizedDescription,
                       expectedSaveError.localizedDescription)
    }
    
    func test_downloadAllIds_callsGraphManager() async {
        let graphManager = FakeNoteGraphManager()
        let testObject = NoteGraphConnector(graphManager: graphManager)

        let expectedIds = (1...5).map { _ in NoteId.testInstance }
        graphManager.downloadAllIds_returnIds = expectedIds

        let ids = await testObject.downloadAllIds()
        
        XCTAssertEqual(graphManager.downloadAllIds_calledCount, 1)
        XCTAssertEqual(ids, expectedIds)
    }
    
    func test_downloadAllIds_whenGraphManagerThrows_publishesError() async throws {
        let graphManager = FakeNoteGraphManager()
        let testObject = NoteGraphConnector(graphManager: graphManager)

        let expectedReadError = GraphStoreReadError
            .readFailure(error: ScryError.testInstance)
        graphManager.downloadAllIds_error = expectedReadError

        let ids = await testObject.downloadAllIds()

        let error = try await waitForResult(testObject.graphStoreError)

        guard case GraphStoreError.readError(let readError) = error else {
            XCTFail("Unexpected error: \(error.localizedDescription)")
            return
        }

        XCTAssertEqual(readError.localizedDescription,
                       expectedReadError.localizedDescription)
        XCTAssertEqual(ids, [])
    }
    
    func test_uploadGraphStoreNote_callsGraphManager() async {
        let graphManager = FakeNoteGraphManager()
        let testObject = NoteGraphConnector(graphManager: graphManager)

        let expectedContents = NoteContents.testInstance
        let expectedMetadata = NoteMeta.testInstance
        await testObject.uploadGraphStoreNote(contents: expectedContents,
                                              metadata: expectedMetadata)

        XCTAssertEqual(graphManager.uploadGraphStoreNote_calledCount, 1)
        XCTAssertEqual(graphManager.uploadGraphStoreNote_paramContents,
                       expectedContents)
        XCTAssertEqual(graphManager.uploadGraphStoreNote_paramNoteMeta,
                       expectedMetadata)
    }
    
    func test_uploadGraphStoreNote_whenGraphManagerThrows_publishesError() async throws {
        let graphManager = FakeNoteGraphManager()
        let testObject = NoteGraphConnector(graphManager: graphManager)

        let expectedSaveError = GraphStoreSaveError
            .saveFailure(error: PokeError.testInstance)
        graphManager.uploadGraphStoreNote_error = expectedSaveError

        await testObject.uploadGraphStoreNote(contents: NoteContents.testInstance,
                                              metadata: NoteMeta.testInstance)

        let error = try await waitForResult(testObject.graphStoreError)

        guard case GraphStoreError.saveError(let saveError) = error else {
            XCTFail("Unexpected error: \(error.localizedDescription)")
            return
        }

        XCTAssertEqual(saveError.localizedDescription,
                       expectedSaveError.localizedDescription)
    }
}
