import XCTest
import UrsusHTTP
import SwiftGraphStore
@testable import FunesNotes

class GraphStoreSyncTests: XCTestCase {
    func test_doesNotRetain() {
        var testObject: GraphStoreSync? = GraphStoreSync(fileManager: FakeNoteFileManager(),
                                                         graphManager: FakeNoteGraphManager(),
                                                         metadataMonitor: FakeMetadataChangeMonitor())
        
        weak var weakTestObject = testObject
        testObject = nil
        XCTAssertNil(weakTestObject)
    }
    
    func test_whenMonitorPublishesCreations_loadsContentsAndUploads() async {
        let fileManager = FakeNoteFileManager()
        let graphManager = FakeNoteGraphManager()
        let metadataMonitor = FakeMetadataChangeMonitor()
        let testObject = GraphStoreSync(fileManager: fileManager,
                               graphManager: graphManager,
                               metadataMonitor: metadataMonitor)
                        
        let contents = NoteContents.testInstance
        fileManager.loadNoteContents_returnContents = contents
        
        let metadata = NoteMeta.testInstance
        let sentMetadata = [NoteMeta.testInstance,
                            NoteMeta.testInstance,
                            metadata]
        metadataMonitor.metadataCreatedSubject.send(sentMetadata)
        
        await Task.yield()

        XCTAssertEqual(fileManager.loadNoteContents_calledCount, 3)
        XCTAssertEqual(graphManager.uploadGraphStoreNote_calledCount, 3)
        XCTAssertEqual(graphManager.uploadGraphStoreNote_paramContents, contents)
        XCTAssertEqual(graphManager.uploadGraphStoreNote_paramNoteMeta, metadata)
        
        testObject.start()
    }
    
    func test_whenMonitorPublishesCreations_whenFileErrorHappens_publishes() async throws {
        let fileManager = FakeNoteFileManager()
        let graphManager = FakeNoteGraphManager()
        let metadataMonitor = FakeMetadataChangeMonitor()
        let testObject = GraphStoreSync(fileManager: fileManager,
                               graphManager: graphManager,
                               metadataMonitor: metadataMonitor)
                        
        let internalError = NSError(domain: UUID().uuidString, code: 0)
        let expectedError = NoteFileError.loadFailure(error: internalError)
        fileManager.loadNoteContents_error = expectedError
        
        metadataMonitor.metadataCreatedSubject.send([NoteMeta.testInstance])
        
        await Task.yield()
        
        let error = try await waitForResult(testObject.fileError)
        
        XCTAssertEqual(error, expectedError)
    }
    
    func test_whenMonitorPublishesCreations_whenGraphErrorHappens_publishes() async throws {
        let fileManager = FakeNoteFileManager()
        let graphManager = FakeNoteGraphManager()
        let metadataMonitor = FakeMetadataChangeMonitor()
        let testObject = GraphStoreSync(fileManager: fileManager,
                               graphManager: graphManager,
                               metadataMonitor: metadataMonitor)
                        
        let contents = NoteContents.testInstance
        fileManager.loadNoteContents_returnContents = contents
       
        let internalError = PokeError.testInstance
        let expectedError = GraphStoreSaveError.saveFailure(error: internalError)
        graphManager.uploadGraphStoreNote_error = expectedError
        
        metadataMonitor.metadataCreatedSubject.send([NoteMeta.testInstance])
        
        await Task.yield()
        
        let error = try await waitForResult(testObject.graphStoreError)
        
        XCTAssertEqual(error.errorDescription,
                       expectedError.errorDescription)
    }
    
    func test_whenMonitorPublishesUpdates_loadsContentsAndUploads() async throws {
        let fileManager = FakeNoteFileManager()
        let graphManager = FakeNoteGraphManager()
        let metadataMonitor = FakeMetadataChangeMonitor()
        let testObject = GraphStoreSync(fileManager: fileManager,
                                        graphManager: graphManager,
                                        metadataMonitor: metadataMonitor)
                        
        let contents = NoteContents.testInstance
        fileManager.loadNoteContents_returnContents = contents
        
        let metadata = NoteMeta.testInstance
        let sentMetadata = [NoteMeta.testInstance,
                            NoteMeta.testInstance,
                            metadata]
        metadataMonitor.metadataUpdatedSubject.send(sentMetadata)
        
        await Task.yield()
        
        XCTAssertEqual(fileManager.loadNoteContents_calledCount, 3)
        XCTAssertEqual(graphManager.uploadGraphStoreNote_calledCount, 3)
        XCTAssertEqual(graphManager.uploadGraphStoreNote_paramContents, contents)
        XCTAssertEqual(graphManager.uploadGraphStoreNote_paramNoteMeta, metadata)
        
        testObject.start()
    }

    func test_start_startsTheMonitor() async throws {
        let metadataMonitor = FakeMetadataChangeMonitor()
        let testObject = GraphStoreSync(fileManager: FakeNoteFileManager(),
                                        graphManager: FakeNoteGraphManager(),
                                        metadataMonitor: metadataMonitor)
        
        testObject.start()
        
        XCTAssertEqual(metadataMonitor.start_calledCount, 1)
    }
    
    func test_synchronize_uploadsAndDownloads() async {
        let fileManager = FakeNoteFileManager()
        let graphManager = FakeNoteGraphManager()
        
        let testObject = GraphStoreSync(fileManager: fileManager,
                                        graphManager: graphManager,
                                        metadataMonitor: FakeMetadataChangeMonitor())
        
        await testObject.synchronize()
        
        XCTAssertEqual(graphManager.downloadAllIds_calledCount, 1)
        XCTAssertEqual(fileManager.loadNoteMetas_calledCount, 1)
    }
    
    func test_uploadAll_loadsMetadata() async throws {
        let fileManager = FakeNoteFileManager()
        
        let testObject = GraphStoreSync(fileManager: fileManager,
                                        graphManager: FakeNoteGraphManager(),
                                        metadataMonitor: FakeMetadataChangeMonitor())
        
        await testObject.uploadAll()
        
        XCTAssertEqual(fileManager.loadNoteMetas_calledCount, 1)
    }
    
    func test_uploadAll_whenErrorLoadingMetadata_throws() async throws {
        let fileManager = FakeNoteFileManager()
        let testObject = GraphStoreSync(fileManager: fileManager,
                                        graphManager: FakeNoteGraphManager(),
                                        metadataMonitor: FakeMetadataChangeMonitor())
        
        let internalError = NSError(domain: UUID().uuidString, code: 0)
        let expectedError = NoteFileError.loadFailure(error: internalError)
        fileManager.loadNoteMetas_error = expectedError
                
        let error = try await waitForResult(testObject.fileError) {
            await testObject.uploadAll()
        }
        
        XCTAssertEqual(error, expectedError)
        XCTAssertEqual(fileManager.loadNoteContents_calledCount, 0)
    }

    func test_uploadAll_getsContentForAllMetadata() async throws {
        let fileManager = FakeNoteFileManager()
        let testObject = GraphStoreSync(fileManager: fileManager,
                                        graphManager: FakeNoteGraphManager(),
                                        metadataMonitor: FakeMetadataChangeMonitor())
        
        let metadataCount = 5
        let metadatas = (0..<metadataCount).map { _ in NoteMeta.testInstance }
        fileManager.loadNoteMetas_returnedMetas = metadatas
        
        fileManager.loadNoteContents_returnContents = NoteContents.testInstance
        
        await testObject.uploadAll()
        
        XCTAssertEqual(fileManager.loadNoteContents_calledCount, metadataCount)
        XCTAssertEqual(fileManager.loadNoteContents_paramId, metadatas.last!.id )
    }
    
    func test_uploadAll_givesUpAfterFirstMissingContents() async throws {
        let fileManager = FakeNoteFileManager()
        let testObject = GraphStoreSync(fileManager: fileManager,
                                        graphManager: FakeNoteGraphManager(),
                                        metadataMonitor: FakeMetadataChangeMonitor())
        
        let metadataCount = 5
        let metadatas = (0..<metadataCount).map { _ in NoteMeta.testInstance }
        fileManager.loadNoteMetas_returnedMetas = metadatas
        fileManager.loadNoteContents_returnContents = nil
        
        await testObject.uploadAll()
        
        XCTAssertEqual(fileManager.loadNoteContents_calledCount, 1)
        XCTAssertEqual(fileManager.loadNoteContents_paramId, metadatas.first!.id )
    }

    func test_uploadAll_givesUpAfterFirstUploadFailure() async throws {
        let fileManager = FakeNoteFileManager()
        let testObject = GraphStoreSync(fileManager: fileManager,
                                        graphManager: FakeNoteGraphManager(),
                                        metadataMonitor: FakeMetadataChangeMonitor())
        
        let metadataCount = 5
        let metadatas = (0..<metadataCount).map { _ in NoteMeta.testInstance }
        fileManager.loadNoteMetas_returnedMetas = metadatas
        
        await testObject.uploadAll()
        
        XCTAssertEqual(fileManager.loadNoteContents_calledCount, 1)
        XCTAssertEqual(fileManager.loadNoteContents_paramId, metadatas.first!.id )
    }
    
    func test_uploadAll_whenErrorLoadingContents_throws() async throws {
        let fileManager = FakeNoteFileManager()
        let testObject = GraphStoreSync(fileManager: fileManager,
                                        graphManager: FakeNoteGraphManager(),
                                        metadataMonitor: FakeMetadataChangeMonitor())
        
        fileManager.loadNoteMetas_returnedMetas = [NoteMeta.testInstance]
        
        let internalError = NSError(domain: UUID().uuidString, code: 0)
        let expectedError = NoteFileError.loadFailure(error: internalError)
        fileManager.loadNoteContents_error = expectedError
        
        let error = try await waitForResult(testObject.fileError) {
            await testObject.uploadAll()
        }
        
        XCTAssertEqual(error, expectedError)
    }
    
    func test_uploadAll_whenContentsIsNil_publishesError() async throws {
        let fileManager = FakeNoteFileManager()
        let testObject = GraphStoreSync(fileManager: fileManager,
                                        graphManager: FakeNoteGraphManager(),
                                        metadataMonitor: FakeMetadataChangeMonitor())
        
        fileManager.loadNoteMetas_returnedMetas = [NoteMeta.testInstance]
        
        let internalError = CocoaError(.fileReadNoSuchFile)
        let expectedError = NoteFileError.loadFailure(error: internalError)
        fileManager.loadNoteContents_error = expectedError
        
        let error = try await waitForResult(testObject.fileError) {
            await testObject.uploadAll()
        }
        
        XCTAssertEqual(error, expectedError)
    }
    
    func test_uploadAll_callsUpload() async throws {
        let fileManager = FakeNoteFileManager()
        let graphManager = FakeNoteGraphManager()
        let testObject = GraphStoreSync(fileManager: fileManager,
                                        graphManager: graphManager,
                                        metadataMonitor: FakeMetadataChangeMonitor())
        
        let metadata = NoteMeta.testInstance
        fileManager.loadNoteMetas_returnedMetas = [metadata]
        
        let contents = NoteContents.testInstance
        fileManager.loadNoteContents_returnContents = contents
        
        await testObject.uploadAll()
        
        XCTAssertEqual(graphManager.uploadGraphStoreNote_calledCount, 1)
        XCTAssertEqual(graphManager.uploadGraphStoreNote_paramContents, contents)
        XCTAssertEqual(graphManager.uploadGraphStoreNote_paramNoteMeta, metadata)
    }
    
    func test_uploadAll_whenGraphStoreIsNewer_ignoresError() async throws {
        let fileManager = FakeNoteFileManager()
        let graphManager = FakeNoteGraphManager()
        let testObject = GraphStoreSync(fileManager: fileManager,
                                        graphManager: graphManager,
                                        metadataMonitor: FakeMetadataChangeMonitor())
        
        fileManager.loadNoteMetas_returnedMetas = [NoteMeta.testInstance]
        fileManager.loadNoteContents_returnContents = NoteContents.testInstance
        
        graphManager.uploadGraphStoreNote_error = GraphStoreSaveError.graphStoreVersionIsNewer(graphStoreLastModified: .now)
        
        try await waitForNoResult(testObject.graphStoreError) {
            await testObject.uploadAll()
        }
    }

    func test_uploadAll_whenGraphReadFails_publishesError() async throws {
        let fileManager = FakeNoteFileManager()
        let graphManager = FakeNoteGraphManager()
        let testObject = GraphStoreSync(fileManager: fileManager,
                                        graphManager: graphManager,
                                        metadataMonitor: FakeMetadataChangeMonitor())
        
        fileManager.loadNoteMetas_returnedMetas = [NoteMeta.testInstance]
        fileManager.loadNoteContents_returnContents = NoteContents.testInstance
        
        let scryError = ScryError.testInstance
        let readError = GraphStoreReadError.readFailure(error: scryError)
        graphManager.uploadGraphStoreNote_error = readError
        
        let error = try await waitForResult(testObject.graphStoreError) {
            await testObject.uploadAll()
        }
        
        let expectedError = GraphStoreError.readError(error: readError)
        XCTAssertEqual(error.localizedDescription,
                       expectedError.localizedDescription)
    }

    func test_uploadAll_whenGraphSaveFails_publishesError() async throws {
        let fileManager = FakeNoteFileManager()
        let graphManager = FakeNoteGraphManager()
        let testObject = GraphStoreSync(fileManager: fileManager,
                                        graphManager: graphManager,
                                        metadataMonitor: FakeMetadataChangeMonitor())
        
        fileManager.loadNoteMetas_returnedMetas = [NoteMeta.testInstance]
        fileManager.loadNoteContents_returnContents = NoteContents.testInstance
        
        let expectedResource = Resource.testInstance
        let pokeError = PokeError.testInstance
        let saveError = GraphStoreSaveError.createGraphFailure(resource: expectedResource,
                                                                   error: pokeError)
        graphManager.uploadGraphStoreNote_error = saveError
        
        let error = try await waitForResult(testObject.graphStoreError) {
            await testObject.uploadAll()
        }
        
        let expectedError = GraphStoreError.saveError(error: saveError)
        XCTAssertEqual(error.localizedDescription,
                       expectedError.localizedDescription)
    }
    
    func test_downloadAll_requestsAllNoteIdsFromGraphStore() async throws {
        let graphManager = FakeNoteGraphManager()
        let testObject = GraphStoreSync(fileManager: FakeNoteFileManager(),
                                        graphManager: graphManager,
                                        metadataMonitor: FakeMetadataChangeMonitor())
        
        await testObject.downloadAll()
        
        XCTAssertEqual(graphManager.downloadAllIds_calledCount, 1)
    }
    
    func test_downloadAll_whenDownloadIdsFails_publishes() async throws {
        let graphManager = FakeNoteGraphManager()
        let testObject = GraphStoreSync(fileManager: FakeNoteFileManager(),
                                        graphManager: graphManager,
                                        metadataMonitor: FakeMetadataChangeMonitor())
        
        let readError = GraphStoreReadError
            .readFailure(error: ScryError.testInstance)
        graphManager.downloadAllIds_error = readError
        
        let error = try await waitForResult(testObject.graphStoreError) {
            await testObject.downloadAll()
        }
        
        let expectedError = GraphStoreError.readError(error: readError)
        XCTAssertEqual(error.localizedDescription,
                       expectedError.localizedDescription)
    }
    
    func test_downloadAll_getsFileMetadataForAllIds() async {
        let fileManager = FakeNoteFileManager()
        let graphManager = FakeNoteGraphManager()
        let testObject = GraphStoreSync(fileManager: fileManager,
                                        graphManager: graphManager,
                                        metadataMonitor: FakeMetadataChangeMonitor())
        
        let idCount = Int.random(in: 10...20)
        graphManager.downloadAllIds_returnIds = (0..<idCount).map { _ in
            NoteId.testInstance
        }
        
        await testObject.downloadAll()
        
        XCTAssertEqual(fileManager.loadNoteMeta_calledCount, idCount)
    }
    
    func test_downloadAll_getsFileMetadata() async {
        let fileManager = FakeNoteFileManager()
        let graphManager = FakeNoteGraphManager()
        let testObject = GraphStoreSync(fileManager: fileManager,
                                        graphManager: graphManager,
                                        metadataMonitor: FakeMetadataChangeMonitor())

        let noteId = NoteId.testInstance
        graphManager.downloadAllIds_returnIds = [noteId]

        await testObject.downloadAll()

        XCTAssertEqual(fileManager.loadNoteMeta_calledCount, 1)
        XCTAssertEqual(fileManager.loadNoteMeta_paramId, noteId)

    }
    
    func test_downloadAll_whenRetrievingFileMetadataFails_publishesError() async throws {
        let fileManager = FakeNoteFileManager()
        let graphManager = FakeNoteGraphManager()
        let testObject = GraphStoreSync(fileManager: fileManager,
                                        graphManager: graphManager,
                                        metadataMonitor: FakeMetadataChangeMonitor())

        let noteId = NoteId.testInstance
        graphManager.downloadAllIds_returnIds = [noteId]
        
        let internalError = NSError(domain: UUID().uuidString, code: 0)
        let expectedError = NoteFileError.loadFailure(error: internalError)
        fileManager.loadNoteMeta_error = expectedError

        let error = try await waitForResult(testObject.fileError) {
            await testObject.downloadAll()
        }
        
        XCTAssertEqual(error, expectedError)
    }
    
    func test_downloadAll_downloadsFromGraphStore() async throws {
        let fileManager = FakeNoteFileManager()
        let graphManager = FakeNoteGraphManager()
        let testObject = GraphStoreSync(fileManager: fileManager,
                                        graphManager: graphManager,
                                        metadataMonitor: FakeMetadataChangeMonitor())

        graphManager.downloadAllIds_returnIds = [NoteId.testInstance]
        
        let expectedMetadata = NoteMeta.testInstance
        fileManager.loadNoteMeta_returnNoteMeta = expectedMetadata

        await testObject.downloadAll()

        XCTAssertEqual(graphManager.downloadGraphStoreNote_calledCount, 1)
        XCTAssertEqual(graphManager.downloadGraphStoreNote_paramFileMetadata, expectedMetadata)
    }
    
    func test_downloadAll_whenDownloadThrows_publishesError() async throws {
        let fileManager = FakeNoteFileManager()
        let graphManager = FakeNoteGraphManager()
        let testObject = GraphStoreSync(fileManager: fileManager,
                                        graphManager: graphManager,
                                        metadataMonitor: FakeMetadataChangeMonitor())

        graphManager.downloadAllIds_returnIds = [NoteId.testInstance]
        
        let scryError = ScryError.testInstance
        let expectedError = GraphStoreReadError.readFailure(error: scryError)
        graphManager.downloadGraphStoreNote_error = expectedError

        let error = try await waitForResult(testObject.graphStoreError) {
            await testObject.downloadAll()
        }
        
        guard case GraphStoreError.readError(let readError) = error else {
            XCTFail("Unexpected error: \(error.localizedDescription)")
            return
        }
                
        XCTAssertEqual(readError.localizedDescription,
                       expectedError.localizedDescription)
    }
    
    func test_downloadAll_savesContentsAndMetadata() async {
        let fileManager = FakeNoteFileManager()
        let graphManager = FakeNoteGraphManager()
        let testObject = GraphStoreSync(fileManager: fileManager,
                                        graphManager: graphManager,
                                        metadataMonitor: FakeMetadataChangeMonitor())

        graphManager.downloadAllIds_returnIds = [NoteId.testInstance]
        
        fileManager.loadNoteMeta_returnNoteMeta = NoteMeta.testInstance
        
        let expectedContents = NoteContents.testInstance
        graphManager.downloadGraphStoreNote_returnContents = expectedContents
        let returnedMetadata = NoteMeta.testInstance
        graphManager.downloadGraphStoreNote_returnMetadata = returnedMetadata

        await testObject.downloadAll()
        
        XCTAssertEqual(fileManager.saveNoteContents_calledCount, 1)
        XCTAssertEqual(fileManager.saveNoteContents_paramContents, expectedContents)
        let expectedMetadata = NoteMeta(contents: expectedContents,
                                        metadata: returnedMetadata)
        XCTAssertEqual(fileManager.saveNoteMeta_calledCount, 1)
        XCTAssertEqual(fileManager.saveNoteMeta_paramNoteMeta, expectedMetadata)
    }
    
    func test_downloadAll_whenContentFailsAndMetadataSucceeds_usesMetadataFromFile() async {
        let fileManager = FakeNoteFileManager()
        let graphManager = FakeNoteGraphManager()
        let testObject = GraphStoreSync(fileManager: fileManager,
                                        graphManager: graphManager,
                                        metadataMonitor: FakeMetadataChangeMonitor())

        graphManager.downloadAllIds_returnIds = [NoteId.testInstance]
        
        fileManager.loadNoteMeta_returnNoteMeta = NoteMeta.testInstance
        
        graphManager.downloadGraphStoreNote_returnContents = nil
        let returnedMetadata = NoteMeta.testInstance
        graphManager.downloadGraphStoreNote_returnMetadata = returnedMetadata

        let fileContents = NoteContents.testInstance
        fileManager.loadNoteContents_returnContents = fileContents
        
        await testObject.downloadAll()
        
        XCTAssertEqual(fileManager.saveNoteContents_calledCount, 0)
        XCTAssertEqual(fileManager.loadNoteContents_calledCount, 1)

        let expectedMetadata = NoteMeta(contents: fileContents,
                                        metadata: returnedMetadata)
        XCTAssertEqual(fileManager.saveNoteMeta_calledCount, 1)
        XCTAssertEqual(fileManager.saveNoteMeta_paramNoteMeta, expectedMetadata)
    }
    
    func test_downloadAll_whenContentSaveFails_publishesError() async throws {
        let fileManager = FakeNoteFileManager()
        let graphManager = FakeNoteGraphManager()
        let testObject = GraphStoreSync(fileManager: fileManager,
                                        graphManager: graphManager,
                                        metadataMonitor: FakeMetadataChangeMonitor())

        graphManager.downloadAllIds_returnIds = [NoteId.testInstance]
        
        fileManager.loadNoteMeta_returnNoteMeta = NoteMeta.testInstance
        
        graphManager.downloadGraphStoreNote_returnMetadata = NoteMeta.testInstance
        graphManager.downloadGraphStoreNote_returnContents = NoteContents.testInstance

        let internalError = NSError(domain: UUID().uuidString, code: 0)
        let expectedError = NoteFileError.loadFailure(error: internalError)
        fileManager.saveNoteContents_error = expectedError
        
        let error = try await waitForResult(testObject.fileError) {
            await testObject.downloadAll()
        }
        
        XCTAssertEqual(error, expectedError)
    }
    
    func test_downloadAll_whenMetadataSaveFails_publishesError() async throws {
        let fileManager = FakeNoteFileManager()
        let graphManager = FakeNoteGraphManager()
        let testObject = GraphStoreSync(fileManager: fileManager,
                                        graphManager: graphManager,
                                        metadataMonitor: FakeMetadataChangeMonitor())

        graphManager.downloadAllIds_returnIds = [NoteId.testInstance]
        
        fileManager.loadNoteMeta_returnNoteMeta = NoteMeta.testInstance
        
        graphManager.downloadGraphStoreNote_returnMetadata = NoteMeta.testInstance
        graphManager.downloadGraphStoreNote_returnContents = NoteContents.testInstance

        let internalError = NSError(domain: UUID().uuidString, code: 0)
        let expectedError = NoteFileError.loadFailure(error: internalError)
        fileManager.saveNoteMeta_error = expectedError
        
        let error = try await waitForResult(testObject.fileError) {
            await testObject.downloadAll()
        }
        
        XCTAssertEqual(error, expectedError)
    }
}
