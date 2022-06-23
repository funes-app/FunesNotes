@testable import FunesNotes
import XCTest
import Combine

class FileConnectorTests: XCTestCase {
    
    func test_doesNotRetain() async throws {
        var testObject: FileConnector? = FileConnector(noteFileManager: FakeNoteFileManager())
        
        weak var weakTestObject = testObject
        testObject = nil

        XCTAssertNil(weakTestObject)
    }
    
    func test_init_startsMonitorAndSubscribes() async throws {
        let metadataChangeMonitor = FakeMetadataChangeMonitor()
        let testObject = FileConnector(noteFileManager: FakeNoteFileManager(),
                                       metadataChangeMonitor: metadataChangeMonitor)
        
        await Task.yield()
        
        XCTAssertEqual(metadataChangeMonitor.start_calledCount, 1)
        
        let updatedNoteMeta = NoteMeta.testInstance
        metadataChangeMonitor.metadataUpdatedSubject.send([updatedNoteMeta])

        // Avoid testObject being garbage-collected
        let _ = testObject
    }
    
    func test_whenMonitorPublishesCreation_passesThrough() async throws {
        let fileManager = FakeNoteFileManager()
        let metadataChangeMonitor = FakeMetadataChangeMonitor()
        let testObject = FileConnector(noteFileManager: fileManager,
                                       metadataChangeMonitor: metadataChangeMonitor)
        
        let createdMetadata = [NoteMeta.testInstance, NoteMeta.testInstance]
        
        let queue = DispatchQueue(label: "created")
        var cancellables = Set<AnyCancellable>()
        
        var publishedMetadata = [NoteMeta]()
        testObject
            .metadataCreated
            .receive(on: queue)
            .sink(receiveValue: { publishedMetadata.append($0) })
            .store(in: &cancellables)

        metadataChangeMonitor
            .metadataCreatedSubject
            .send(createdMetadata)

        queue.sync { }
        
        XCTAssertEqual(publishedMetadata, createdMetadata)
    }
    
    func test_publishesDeletionsFromMonitor() async throws {
        let fileManager = FakeNoteFileManager()
        let metadataChangeMonitor = FakeMetadataChangeMonitor()
        let testObject = FileConnector(noteFileManager: fileManager,
                                       metadataChangeMonitor: metadataChangeMonitor)
                
        let deletedMetadata = NoteMeta.testInstance.withDeleted(true)
        
        let publisher = testObject
            .noteDeleted
        let publishedId = try await waitForResult(publisher) {
            metadataChangeMonitor.metadataUpdatedSubject.send([deletedMetadata])
        }
        
        XCTAssertEqual(publishedId, deletedMetadata.id)
    }
    
    func test_whenUpdatedFileNotDeleted_doesNotPublishDeletion() async throws {
        let noteFileManager = FakeNoteFileManager()
        let metadataChangeMonitor = FakeMetadataChangeMonitor()
        let testObject = FileConnector(noteFileManager: noteFileManager,
                                       metadataChangeMonitor: metadataChangeMonitor)
        
        let metadata = NoteMeta.testInstance.withDeleted(false)
                
        let publisher = testObject
            .noteDeleted
        try await waitForNoResult(publisher) {
            metadataChangeMonitor.metadataUpdatedSubject.send([metadata])
        }
    }
    
    func test_publishesUpdatesFromMonitor() async throws {
        let fileManager = FakeNoteFileManager()
        let metadataChangeMonitor = FakeMetadataChangeMonitor()
        let testObject = FileConnector(noteFileManager: fileManager,
                                       metadataChangeMonitor: metadataChangeMonitor)
        
        let metadata = NoteMeta.testInstance
            .withDeleted(false)
        
        let publisher = testObject
            .metadataUpdated
        let publishedMetadata = try await waitForResult(publisher) {
            metadataChangeMonitor
                .metadataUpdatedSubject
                .send([metadata])
        }
        
        XCTAssertEqual(publishedMetadata, metadata)
    }
    
    func test_whenUpdatedFileDeleted_doesNotPublishUpdate() async throws {
        let metadataChangeMonitor = FakeMetadataChangeMonitor()
        let testObject = FileConnector(noteFileManager: FakeNoteFileManager(),
                                       metadataChangeMonitor: metadataChangeMonitor)
        
        let metadata = NoteMeta.testInstance.withDeleted(false)
        
        let deletedMetadata = metadata.withDeleted(false)
        
        let publisher = testObject
            .noteDeleted
        try await waitForNoResult(publisher) {
            metadataChangeMonitor.metadataUpdatedSubject.send([deletedMetadata])
        }
    }
    
    func test_fileError_publisherPassesThroughChangesToVar() async throws {
        let testObject = FileConnector(noteFileManager: FakeNoteFileManager())
        
        let error = CocoaError(.executableLink)
        let expectedError = NoteFileError.loadFailure(error: error)
        
        let publisher = testObject
            .fileError
            .eraseToAnyPublisher()
        let returnedError = try await waitForResult(publisher) {
            testObject._fileError = expectedError
        }
        
        XCTAssertEqual(returnedError, expectedError)
    }
    
    func test_stopMonitor_stopsTheMonitor() {
        let monitor = FakeMetadataChangeMonitor()
        
        let testObject = FileConnector(noteFileManager: FakeNoteFileManager(),
                                       metadataChangeMonitor: monitor)
        
        testObject.stopMonitor()
        
        XCTAssertEqual(monitor.stop_calledCount, 1)
    }

    func test_loadNoteContents_asksForNoteByID() {
        let noteFileManager = FakeNoteFileManager()

        let testObject = FileConnector(noteFileManager: noteFileManager)

        let id = NoteId.testInstance
        let _ = testObject.loadNoteContents(id: id)

        XCTAssertEqual(noteFileManager.loadNoteContents_calledCount, 1)
        XCTAssertEqual(noteFileManager.loadNoteContents_paramId, id)
    }

    func test_loadNoteContents_returnsTheLoadedNote() {
        let noteFileManager = FakeNoteFileManager()

        let expectedContents = NoteContents.testInstance
        noteFileManager.loadNoteContents_returnContents = expectedContents

        let testObject = FileConnector(noteFileManager: noteFileManager)

        let contents = testObject.loadNoteContents(id: NoteId.testInstance)

        XCTAssertEqual(contents, expectedContents)
    }
    
    func test_loadNoteContents_whenNoNoteFound_returnsNil() {
        let noteFileManager = FakeNoteFileManager()

        noteFileManager.loadNoteContents_returnContents = nil

        let testObject = FileConnector(noteFileManager: noteFileManager)

        let contents = testObject.loadNoteContents(id: NoteId.testInstance)

        XCTAssertNil(contents)
    }
    
    // NB: the noteFileManager.loadNote() should never throw anything but a NoteLoadError
    func test_loadNoteContents_whenFileManagerThrows_setsLoadErrorAndReturnsNil() {
        let noteFileManager = FakeNoteFileManager()

        let internalError = URLError(.cannotOpenFile)
        let loadError = NoteFileError.loadFailure(error: internalError)
        noteFileManager.loadNoteContents_error = loadError

        let testObject = FileConnector(noteFileManager: noteFileManager)

        let contents = testObject.loadNoteContents(id: NoteId.testInstance)

        XCTAssertEqual(testObject._fileError, loadError)
        XCTAssertNil(contents)
    }
    
    func test_loadNoteMetadata_asksForMetadataByID() {
        let noteFileManager = FakeNoteFileManager()

        let testObject = FileConnector(noteFileManager: noteFileManager)

        let id = NoteId.testInstance
        let _ = testObject.loadNoteMetadata(id: id)

        XCTAssertEqual(noteFileManager.loadNoteMeta_calledCount, 1)
        XCTAssertEqual(noteFileManager.loadNoteMeta_paramId, id)
    }

    func test_loadNoteMetadata_returnsTheLoadedMetadata() {
        let noteFileManager = FakeNoteFileManager()

        let expectedMetadata = NoteMeta.testInstance
        noteFileManager.loadNoteMeta_returnNoteMeta = expectedMetadata

        let testObject = FileConnector(noteFileManager: noteFileManager)

        let metadata = testObject.loadNoteMetadata(id: NoteId.testInstance)

        XCTAssertEqual(metadata, expectedMetadata)
    }
    
    func test_loadNoteMetadata_whenNoNoteFound_returnsNil() {
        let noteFileManager = FakeNoteFileManager()

        noteFileManager.loadNoteMeta_returnNoteMeta = nil

        let testObject = FileConnector(noteFileManager: noteFileManager)

        let contents = testObject.loadNoteMetadata(id: NoteId.testInstance)

        XCTAssertNil(contents)
    }
    
    // NB: the noteFileManager.loadNote() should never throw anything but a NoteLoadError
    func test_loadNoteMetadata_whenFileManagerThrows_setsLoadErrorAndReturnsNil() async throws {
        let noteFileManager = FakeNoteFileManager()

        let internalError = URLError(.cannotOpenFile)
        let loadError = NoteFileError.loadFailure(error: internalError)
        noteFileManager.loadNoteContents_error = loadError

        let testObject = FileConnector(noteFileManager: noteFileManager)

        let contents = testObject.loadNoteContents(id: NoteId.testInstance)

        let fileError = try await waitForResult(testObject.fileError)
        XCTAssertEqual(fileError.localizedDescription, loadError.localizedDescription)
        XCTAssertNil(contents)
    }
    
    func test_loadNoteMetas_retrievesMetasFromNoteFileManager() async {
        let noteFileManager = FakeNoteFileManager()
        
        let returnedNoteMetas = (0...5).map { _ in
            NoteMeta.testInstance
        }
        noteFileManager.loadNoteMetas_returnedMetas = returnedNoteMetas
        
        let testObject = FileConnector(noteFileManager: noteFileManager)
        
        let noteMetas = await testObject.loadNoteMetas()
        
        XCTAssertEqual(noteFileManager.loadNoteMetas_calledCount, 1)
        XCTAssertEqual(noteMetas, returnedNoteMetas)
    }
    
    func test_loadNoteMetas_whenNoNotesFound_returnsEmptyList() async {
        let noteFileManager = FakeNoteFileManager()
        noteFileManager.loadNoteMetas_returnedMetas = []

        let testObject = FileConnector(noteFileManager: noteFileManager)
        
        let noteMetas = await testObject.loadNoteMetas()

        XCTAssert(noteMetas.isEmpty)
    }

    func test_loadNoteMetas_whenErrorThrown_setsLoadNoteError_andReturnsEmptyArray() async throws {
        let noteFileManager = FakeNoteFileManager()

        let internalError = URLError(.cannotOpenFile)
        let loadError = NoteFileError.loadFailure(error: internalError)
        noteFileManager.loadNoteMetas_error = loadError

        let testObject = FileConnector(noteFileManager: noteFileManager)

        let noteMetas = await testObject.loadNoteMetas()

        XCTAssertEqual(testObject._fileError, loadError)
        XCTAssert(noteMetas.isEmpty)
    }

    // NB: the noteFileManager.loadNoteMetas() should never throw anything but a NoteLoadError
    func test_loadNoteMetas_whenErrorIsNotNoteLoadError_ignoresTheError() async {
        let noteFileManager = FakeNoteFileManager()

        noteFileManager.loadNoteMetas_error = URLError(.badURL)

        let testObject = FileConnector(noteFileManager: noteFileManager)

        let noteMetas = await testObject.loadNoteMetas()

        XCTAssertNil(testObject._fileError)
        XCTAssert(noteMetas.isEmpty)
    }
    
    func test_save_savesTheNoteAndMetadata() {
        let noteFileManager = FakeNoteFileManager()
        
        let testObject = FileConnector(noteFileManager: noteFileManager)
        
        let contents = NoteContents.testInstance
        let metadata = NoteMeta(contents)
        testObject.save(contents: contents, metadata: metadata)
        
        XCTAssertEqual(noteFileManager.saveNoteContents_calledCount, 1)
        XCTAssertEqual(noteFileManager.saveNoteContents_paramContents, contents)

        XCTAssertEqual(noteFileManager.saveNoteMeta_calledCount, 1)
        XCTAssertEqual(noteFileManager.saveNoteMeta_paramNoteMeta, metadata)
    }
    
    func test_save_whenSaveNoteErrors_setsPublishedError() throws {
        let noteFileManager = FakeNoteFileManager()
        let internalError = URLError(.cannotWriteToFile)
        let saveError = NoteFileError.saveFailure(error: internalError)
        noteFileManager.saveNoteContents_error = saveError
        
        let testObject = FileConnector(noteFileManager: noteFileManager)
        
        testObject.save(contents: .testInstance, metadata: .testInstance)
        
        XCTAssertEqual(testObject._fileError, saveError)
    }
    
    func test_save_whenSaveNoteMetaErrors_setsPublishedError() throws {
        let noteFileManager = FakeNoteFileManager()

        let internalError = URLError(.dnsLookupFailed)
        let saveError = NoteFileError.saveFailure(error: internalError)
        noteFileManager.saveNoteMeta_error = saveError

        let testObject = FileConnector(noteFileManager: noteFileManager)

        testObject.save(contents: .testInstance, metadata: .testInstance)

        XCTAssertEqual(testObject._fileError, saveError)
    }

    // NB: the noteFileManager.save() should never throw anything but a NoteSaveError
    func test_save_whenNoteSaveErrorIsNotNoteSaveError_ignoresTheError() {
        let noteFileManager = FakeNoteFileManager()
        noteFileManager.saveNoteContents_error = URLError(.cannotWriteToFile)

        let testObject = FileConnector(noteFileManager: noteFileManager)

        testObject.save(contents: .testInstance, metadata: .testInstance)

        XCTAssertNil(testObject._fileError)
    }

    func test_save_whenMetadataSaveErrorIsNotNoteSaveError_ignoresTheError() {
        let noteFileManager = FakeNoteFileManager()
        noteFileManager.saveNoteMeta_error = URLError(.cannotWriteToFile)

        let testObject = FileConnector(noteFileManager: noteFileManager)

        testObject.save(contents: .testInstance, metadata: .testInstance)

        XCTAssertNil(testObject._fileError)
    }
    
    func test_delete_loadsMetadataAndUpdatesDeleteFlagAndModified() throws {
        let noteFileManager = FakeNoteFileManager()

        let testObject = FileConnector(noteFileManager: noteFileManager)

        let contents = NoteContents.testInstance
        
        let metadata = NoteMeta(contents)
            .withDeleted(false)
            .withMetadataLastModified(.distantPast)
        noteFileManager.loadNoteMeta_returnNoteMeta = metadata

        testObject.delete(id: contents.id)

        let expectedNoteMeta = metadata
            .withDeleted(true)
            .withMetadataLastModified(.now)

        XCTAssertEqual(noteFileManager.loadNoteMeta_calledCount, 1)
        XCTAssertEqual(noteFileManager.loadNoteMeta_paramId, contents.id)

        XCTAssertEqual(noteFileManager.saveNoteMeta_calledCount, 1)
        XCTAssert(noteFileManager.saveNoteMeta_paramNoteMeta!.equalWithinTimeframe(expectedNoteMeta))
    }
    
    func test_delete_whenNoteLoadThrows_setsPublishedError() async throws {
        let noteFileManager = FakeNoteFileManager()
        
        let internalError = URLError(.cannotRemoveFile)
        let loadError = NoteFileError.loadFailure(error: internalError)
        noteFileManager.loadNoteMeta_error = loadError

        let testObject = FileConnector(noteFileManager: noteFileManager)

        try await waitForNoResult(testObject.noteDeleted) {
            testObject.delete(id: NoteId.testInstance)
        }
        let expectedError = NoteFileError.deleteFailure(error: internalError)
        XCTAssertEqual(testObject._fileError, expectedError)
    }
    
    func test_delete_whenNoteSaveThrows_setsPublishedError() async throws {
        let noteFileManager = FakeNoteFileManager()
        
        noteFileManager.loadNoteMeta_returnNoteMeta = NoteMeta.testInstance
        
        let internalError = URLError(.cannotRemoveFile)
        let saveError = NoteFileError.saveFailure(error: internalError)
        noteFileManager.saveNoteMeta_error = saveError

        let testObject = FileConnector(noteFileManager: noteFileManager)

        try await waitForNoResult(testObject.noteDeleted) {
            testObject.delete(id: NoteId.testInstance)
        }
        
        let expectedError = NoteFileError.deleteFailure(error: internalError)
        XCTAssertEqual(testObject._fileError, expectedError)
    }
    
    func test_deleteAllFiles_callsFileManager() {
        let noteFileManager = FakeNoteFileManager()
        
        let testObject = FileConnector(noteFileManager: noteFileManager)
        
        testObject.deleteAllFiles()
        
        XCTAssertEqual(noteFileManager.deleteAllFiles_calledCount, 1)
    }
    
    func test_deleteAllFiles_whenFileManagerThrows_publishesError()  async throws{
        let noteFileManager = FakeNoteFileManager()
        
        let testObject = FileConnector(noteFileManager: noteFileManager)
        
        let deleteError = URLError(.cannotRemoveFile)
        noteFileManager.deleteAllFiles_error = deleteError

        let error = try await waitForResult(testObject.fileError) {
            testObject.deleteAllFiles()
        }
        
        let expectedError = NoteFileError.deleteFailure(error: deleteError)
        XCTAssertEqual(error, expectedError)
    }
}

extension FileConnector {
    convenience init(noteFileManager: NoteFileManaging) {
        self.init(noteFileManager: noteFileManager,
                  metadataChangeMonitor: FakeMetadataChangeMonitor())
    }
}
