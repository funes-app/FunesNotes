import XCTest
import UrsusHTTP
@testable import FunesNotes

class NoteListViewModelTests: XCTestCase {
    private var userDefaults: UserDefaults!
    
    override func setUpWithError() throws {
        
        userDefaults = UserDefaults(suiteName: #file)
        userDefaults.removePersistentDomain(forName: #file)
    }
    
    func test_doesNotRetain() {
        var testObject: NoteListViewModel? = NoteListViewModel(userDefaults: userDefaults)
        
        weak var weakTestObject = testObject
        testObject = nil
        XCTAssertNil(weakTestObject)
    }
    
    func test_showProgress_whenNotIdle_returnsTrue() {
        let testObject = NoteListViewModel(noteEditViewModel: FakeNoteEditViewModel(),
                                           userDefaults: userDefaults)
        
        testObject.syncActivity = .idle
        XCTAssertEqual(testObject.showSyncProgress, false)

        testObject.syncActivity = .uploading
        XCTAssertEqual(testObject.showSyncProgress, true)
        testObject.syncActivity = .downloading
        XCTAssertEqual(testObject.showSyncProgress, true)
    }
    
    func test_showEditNoteView_unset_clearsLastSelectedNote() {
        let editViewModel = FakeNoteEditViewModel()
        let testObject = NoteListViewModel(noteEditViewModel: editViewModel,
                                           userDefaults: userDefaults)
        
        testObject.showEditNoteView = false
        XCTAssertNil(userDefaults.lastSelectedNoteId)
    }
    
    func test_showEditNoteView_set_doesNotDeselect() {
        let lastSelectedNoteId = NoteId.testInstance
        userDefaults.lastSelectedNoteId = lastSelectedNoteId

        let testObject = NoteListViewModel(fileConnector: FakeFileConnector(),
                                           shipSession: FakeShipSession(),
                                           graphStoreSync: nil,
                                           noteEditViewModel: FakeNoteEditViewModel(),
                                           userDefaults: userDefaults)

        testObject.showEditNoteView = true

        XCTAssertEqual(userDefaults.lastSelectedNoteId,
                       lastSelectedNoteId)
    }
    
    func test_sigilURL_usesShipLink() throws {
        let shipName = "sampel-palnet"
        let ship = try Ship(string: shipName)
        
        let session = FakeShipSession()
        session.ship = ship
        
        let testObject = NoteListViewModel(fileConnector: FakeFileConnector(),
                                           shipSession: session,
                                           graphStoreSync: nil,
                                           noteEditViewModel: FakeNoteEditViewModel(),
                                           userDefaults: userDefaults)
        
        let expectedURLString = "https://api.urbit.live/images/~\(shipName)_black.png"
        let expectedURL = URL(string: expectedURLString)!
        XCTAssertEqual(testObject.sigilURL, expectedURL)
    }
    
    func test_sigilURL_whenComet_usesZodLink() throws {
        let shipName = "~sopdex-nolful-savtus-ladlex--savtug-worsyr-sitsev-marzod"
        let ship = try Ship(string: shipName)
        
        let session = FakeShipSession()
        session.ship = ship
        
        let testObject = NoteListViewModel(fileConnector: FakeFileConnector(),
                                           shipSession: session,
                                           graphStoreSync: nil,
                                           noteEditViewModel: FakeNoteEditViewModel(),
                                           userDefaults: userDefaults)
        
        let expectedURLString = "https://api.urbit.live/images/zod_black.png"
        let expectedURL = URL(string: expectedURLString)!
        XCTAssertEqual(testObject.sigilURL, expectedURL)
    }
    
    func test_sigilURL_whenMoon_usesParentLink() throws {
        let shipName = "salhep-havmug-ribben-donnyl"

        let ship = try Ship(string: shipName)
        
        let session = FakeShipSession()
        session.ship = ship
        
        let testObject = NoteListViewModel(fileConnector: FakeFileConnector(),
                                           shipSession: session,
                                           graphStoreSync: nil,
                                           noteEditViewModel: FakeNoteEditViewModel(),
                                           userDefaults: userDefaults)
        
        let expectedURLString = "https://api.urbit.live/images/~ribben-donnyl_black.png"
        let expectedURL = URL(string: expectedURLString)!
        XCTAssertEqual(testObject.sigilURL, expectedURL)
    }
    
    
    func test_init_whenSelectedNoteIsNil_doesNotShowNote() {
        let editViewModel = FakeNoteEditViewModel()
        userDefaults.lastSelectedNoteId = nil

        let testObject = NoteListViewModel(noteEditViewModel: editViewModel,
                                           userDefaults: userDefaults)

        XCTAssertEqual(editViewModel.loadNoteContents_calledCount, 0)
        XCTAssertEqual(testObject.showEditNoteView, false)
        XCTAssertNil(userDefaults.lastSelectedNoteId)
    }
    
    func test_refresh_reloadsNoteMetas() async {
        let fileConnector = FakeFileConnector()

        let testObject = NoteListViewModel(fileConnector: fileConnector,
                                           userDefaults: userDefaults)
        
        await testObject.refresh()
        
        XCTAssertEqual(fileConnector.loadNoteMetas_calledCount, 1)
    }
    
    func test_refresh_synchronizesWithGraphStore() async {
        let graphStoreSync = FakeGraphStoreSync()
        
        let testObject = NoteListViewModel(graphStoreSync: graphStoreSync,
                                           userDefaults: userDefaults)
        
        await testObject.refresh()
        
        XCTAssertEqual(graphStoreSync.synchronize_calledCount, 1)
    }

    func test_loadNoteMetas_returnsMetadataFromFileConnectorInOrder() async {
        let fileConnector = FakeFileConnector()
        
        let returnedNoteMetas = (0...5).map { _ in
            NoteMeta.testInstance
        }.shuffled()
        
        fileConnector.loadNoteMetas_returnNoteMetas = returnedNoteMetas
        
        let testObject = NoteListViewModel(fileConnector: fileConnector,
                                           userDefaults: userDefaults)
        
        await testObject.loadNoteMetas()
        
        XCTAssertEqual(fileConnector.loadNoteMetas_calledCount, 1)
        XCTAssertEqual(testObject.noteMetas,
                       returnedNoteMetas.ordered())
    }
    
    func test_loadNoteMetas_filtersDeletedNotes() async {
        let fileConnector = FakeFileConnector()
        
        let undeleted = (0...5).map { _ in
            NoteMeta.testInstance.withDeleted(false)
        }
        
        let deleted = (0...5).map { _ in
            NoteMeta.testInstance.withDeleted(true)
        }
        
        let returnedNoteMetas = (undeleted + deleted).shuffled()
        fileConnector.loadNoteMetas_returnNoteMetas = returnedNoteMetas
        
        let testObject = NoteListViewModel(fileConnector: fileConnector,
                                           userDefaults: userDefaults)
        
        await testObject.loadNoteMetas()

        XCTAssertEqual(testObject.noteMetas,
                       undeleted.ordered())
    }
    
    func test_loadNoteMetas_whenNoNotesFound_storesEmptyList() async {
        let fileConnector = FakeFileConnector()
        fileConnector.loadNoteMetas_returnNoteMetas = []
        
        let testObject = NoteListViewModel(fileConnector: fileConnector,
                                           userDefaults: userDefaults)
        
        testObject.noteMetas = [ NoteMeta.testInstance,
                                 NoteMeta.testInstance ]
        
        await testObject.loadNoteMetas()
        
        XCTAssert(testObject.noteMetas.isEmpty)
    }
    
    func test_loadsLastSelectedNote_loadsFromUserDefaultsAndShowsEditor() {
        let editViewModel = FakeNoteEditViewModel()
        let expectedSelectedNoteId = NoteId.testInstance
        userDefaults.lastSelectedNoteId = expectedSelectedNoteId
        
        let testObject = NoteListViewModel(noteEditViewModel: editViewModel,
                                           userDefaults: userDefaults)
        
        testObject.loadLastSelectedNote()
        
        XCTAssertEqual(editViewModel.loadNoteContents_calledCount, 1)
        XCTAssertEqual(editViewModel.loadNoteContents_paramId, expectedSelectedNoteId)
        XCTAssertEqual(testObject.showEditNoteView, true)
        XCTAssertEqual(userDefaults.lastSelectedNoteId, expectedSelectedNoteId)
    }
    func test_loadsLastSelectedNote_whenNoSelectedNote_doesNothing() {
        let editViewModel = FakeNoteEditViewModel()
        userDefaults.lastSelectedNoteId = nil
        
        let testObject = NoteListViewModel(noteEditViewModel: editViewModel,
                                           userDefaults: userDefaults)

        testObject.loadLastSelectedNote()
        
        XCTAssertEqual(editViewModel.loadNoteContents_calledCount, 0)
        XCTAssertEqual(testObject.showEditNoteView, false)
        XCTAssertEqual(userDefaults.lastSelectedNoteId, nil)
    }
    
    func test_loadsLastSelectedNote_whenSelectedNoteAlreadyLoaded_doesNotReload() {
        let editViewModel = FakeNoteEditViewModel()
        let contents = NoteContents.testInstance
        userDefaults.lastSelectedNoteId = contents.id
        
        let testObject = NoteListViewModel(noteEditViewModel: editViewModel,
                                           userDefaults: userDefaults)

        testObject.selectNote(id: contents.id)
        
        editViewModel.loadNoteContents_calledCount = 0
        
        testObject.loadLastSelectedNote()
        
        XCTAssertEqual(editViewModel.loadNoteContents_calledCount, 0)
    }
    
    func test_createPublished_addsCreatedMetadataToMetadataList() {
        let fileConnector = FakeFileConnector()
        let dispatchQueue = DispatchQueue(label: "test queue")

        let testObject = NoteListViewModel(fileConnector: fileConnector,
                                           userDefaults: userDefaults,
                                           dispatchQueue: dispatchQueue)
        
        let metadatas = [NoteMeta.testInstance,
                         NoteMeta.testInstance]
        testObject.noteMetas = metadatas
        
        let newMetadata = NoteMeta.testInstance
        fileConnector
            .metadataCreatedSubject
            .send(newMetadata)
        
        dispatchQueue.sync {}
        
        let expectedNoteMetas = [newMetadata] + metadatas
        XCTAssertEqual(testObject.noteMetas.count, expectedNoteMetas.count)
        XCTAssertEqual(Set(testObject.noteMetas), Set(expectedNoteMetas))
    }
    
    func test_updatePublished_updatesMetadataList() {
        let fileConnector = FakeFileConnector()
        let dispatchQueue = DispatchQueue(label: "test queue")

        let testObject = NoteListViewModel(fileConnector: fileConnector,
                                           userDefaults: userDefaults,
                                           dispatchQueue: dispatchQueue)
        
        let contents = NoteContents.testInstance
        let metadata = NoteMeta(contents).withDeleted(false)
        let otherMetadata = [NoteMeta.testInstance,
                             NoteMeta.testInstance]
        testObject.noteMetas = [metadata] + otherMetadata
        
        let updatedMetadata = NoteMeta(contents).withDeleted(true)
        fileConnector
            .metadataUpdatedSubject
            .send(updatedMetadata)
        
        dispatchQueue.sync {}
        
        let expectedNoteMetas = [updatedMetadata] + otherMetadata
        XCTAssertEqual(testObject.noteMetas.count, expectedNoteMetas.count)
        XCTAssertEqual(Set(testObject.noteMetas), Set(expectedNoteMetas))
    }
    
    func test_deletePublished_removesDeletedNoteFromMetadataList() {
        let fileConnector = FakeFileConnector()
        let dispatchQueue = DispatchQueue(label: "test queue")

        let testObject = NoteListViewModel(fileConnector: fileConnector,
                                           userDefaults: userDefaults,
                                           dispatchQueue: dispatchQueue)
        
        let contents = NoteContents.testInstance
        let noteMetas = [NoteMeta.testInstance,
                         NoteMeta(contents),
                         NoteMeta.testInstance]
        testObject.noteMetas = noteMetas
        
        fileConnector
            .noteDeletedSubject
            .send(contents.id)
        
        dispatchQueue.sync {}
        
        let expectedNoteMetas = [noteMetas[0], noteMetas[2]]
        XCTAssertEqual(testObject.noteMetas.count, expectedNoteMetas.count)
        XCTAssertEqual(testObject.noteMetas, expectedNoteMetas)

    }
    
    func test_deletePublished_whenIdNotFound_noChanges() {
        let fileConnector = FakeFileConnector()
        let dispatchQueue = DispatchQueue(label: "deleted")
        let testObject = NoteListViewModel(fileConnector: fileConnector,
                                           userDefaults: userDefaults,
                                           dispatchQueue: dispatchQueue)
        
        let noteMetas = [NoteMeta.testInstance,
                         NoteMeta.testInstance,
                         NoteMeta.testInstance]
        testObject.noteMetas = noteMetas
        
        fileConnector
            .noteDeletedSubject
            .send(NoteId.testInstance)
        
        dispatchQueue.sync {}

        XCTAssertEqual(testObject.noteMetas, noteMetas)
    }
    
    func test_deletePublished_whenMatchesSelectedId_loadsNextSelectedNoteId() {
        let fileConnector = FakeFileConnector()
        let editViewModel = FakeNoteEditViewModel()
        let dispatchQueue = DispatchQueue(label: "deleted")
        let testObject = NoteListViewModel(fileConnector: fileConnector,
                                           shipSession: FakeShipSession(),
                                           graphStoreSync: nil,
                                           noteEditViewModel: editViewModel,
                                           userDefaults: userDefaults,
                                           dispatchQueue: dispatchQueue)
        
        let contents = NoteContents.testInstance
        testObject.selectNote(id: contents.id)
        testObject.showEditNoteView = true
        userDefaults.lastSelectedNoteId = contents.id
        
        editViewModel.loadNoteContents_calledCount = 0

        let nextContents = NoteContents.testInstance
        let noteMetas = [NoteMeta.testInstance,
                         NoteMeta(contents),
                         NoteMeta(nextContents)]
        testObject.noteMetas = noteMetas
        
        fileConnector
            .noteDeletedSubject
            .send(contents.id)
        
        dispatchQueue.sync {}

        XCTAssertEqual(editViewModel.loadNoteContents_calledCount, 1)
        XCTAssertEqual(editViewModel.loadNoteContents_paramId, nextContents.id)
        XCTAssertEqual(testObject.showEditNoteView, true)
        XCTAssertEqual(userDefaults.lastSelectedNoteId, nextContents.id)
    }
    
    func test_deletePublished_whenLastNoteDeleted_clearsSelectionAndDoesNewNote() {
        let fileConnector = FakeFileConnector()
        let editViewModel = FakeNoteEditViewModel()
        let dispatchQueue = DispatchQueue(label: "deleted")
        let testObject = NoteListViewModel(fileConnector: fileConnector,
                                           shipSession: FakeShipSession(),
                                           graphStoreSync: nil,
                                           noteEditViewModel: editViewModel,
                                           userDefaults: userDefaults,
                                           dispatchQueue: dispatchQueue)
        
        let contents = NoteContents.testInstance
        testObject.selectNote(id: contents.id)
        testObject.showEditNoteView = true
        userDefaults.lastSelectedNoteId = contents.id
        
        editViewModel.loadNoteContents_calledCount = 0
        editViewModel.newNoteContents_calledCount = 0
        
        fileConnector
            .noteDeletedSubject
            .send(contents.id)
        
        dispatchQueue.sync {}

        XCTAssertEqual(editViewModel.loadNoteContents_calledCount, 0)
        XCTAssertEqual(editViewModel.newNoteContents_calledCount, 1)
        XCTAssertEqual(testObject.showEditNoteView, false)
        XCTAssertNil(userDefaults.lastSelectedNoteId)
    }
    
    func test_deletePublished_whenDoesNotMatch_doesNotClearSelectedId() {
        let fileConnector = FakeFileConnector()
        let editViewModel = FakeNoteEditViewModel()
        let testObject = NoteListViewModel(fileConnector: fileConnector,
                                           shipSession: FakeShipSession(),
                                           graphStoreSync: nil,
                                           noteEditViewModel: editViewModel,
                                           userDefaults: userDefaults)

        let contents = NoteContents.testInstance
        editViewModel.noteContentsBeingEdited = contents
        testObject.showEditNoteView = true
        userDefaults.lastSelectedNoteId = contents.id

        let otherId = NoteId.testInstance
        fileConnector
            .noteDeletedSubject
            .send(otherId)

        XCTAssertEqual(editViewModel.loadNoteContents_calledCount, 0)
        XCTAssertEqual(testObject.showEditNoteView, true)
        XCTAssertEqual(userDefaults.lastSelectedNoteId, contents.id)
    }
    
    func test_showDeletionConfirmation_setsFlagsAndValues() {
        let testObject = NoteListViewModel(userDefaults: userDefaults)
        
        let noteMeta = NoteMeta.testInstance
        testObject.showDeletionConfirmation(noteMeta: noteMeta)
        
        XCTAssertEqual(testObject.noteMetaToDelete, noteMeta)
        XCTAssertEqual(testObject.showDeleteConfirmation, true)
    }
    
    func test_delete_callsDeleteOnFileVM() {
        let fileConnector = FakeFileConnector()
        let testObject = NoteListViewModel(fileConnector: fileConnector,
                                           userDefaults: userDefaults)
        
        let noteMeta = NoteMeta.testInstance
        testObject.showDeletionConfirmation(noteMeta: noteMeta)

        testObject.delete()
        
        XCTAssertEqual(fileConnector.delete_calledCount, 1)
        XCTAssertEqual(fileConnector.delete_paramId, noteMeta.id)
    }
    
    func test_delete_whenNoteToDeleteIsNil_noAction() {
        let fileConnector = FakeFileConnector()
        let testObject = NoteListViewModel(fileConnector: fileConnector,
                                           userDefaults: userDefaults)

        testObject.delete()
        
        XCTAssertEqual(fileConnector.delete_calledCount, 0)
    }
    
    func test_sigilTapped_showsLogoutConfirmation() {
        let testObject = NoteListViewModel(userDefaults: userDefaults)
        
        testObject.sigilTapped()
        
        XCTAssertEqual(testObject.showLogoutConfirmation, true)
    }
    
    func test_logout_callsAppVM() async {
        let appViewModel = FakeAppViewModel()
        let testObject = NoteListViewModel(appViewModel: appViewModel)
        
        await testObject.logout()
        
        XCTAssertEqual(appViewModel.logout_calledCount, 1)
    }
    
    func test_createNewNoteTapped_createsNewNoteAndDisplaysEditor() {
        let editViewModel = FakeNoteEditViewModel()
        let testObject = NoteListViewModel(noteEditViewModel: editViewModel,
                                           userDefaults: userDefaults)

        testObject.showEditNoteView = false
        testObject.createNewNoteTapped()

        XCTAssertEqual(editViewModel.newNoteContents_calledCount, 1)
        XCTAssertEqual(testObject.showEditNoteView, true)
    }
    
    func test_createNewNoteTapped_updatesUserDefaults() {
        let editViewModel = FakeNoteEditViewModel()
        let testObject = NoteListViewModel(noteEditViewModel: editViewModel,
                                           userDefaults: userDefaults)

        let contentsBeingEdited = NoteContents.testInstance
        editViewModel.noteContentsBeingEdited = contentsBeingEdited

        testObject.createNewNoteTapped()

        XCTAssertEqual(userDefaults.lastSelectedNoteId, contentsBeingEdited.id)
    }
    
    func test_selectNote_updatesUserDefaults() {
        let testObject = NoteListViewModel(fileConnector: FakeFileConnector(),
                                           shipSession: FakeShipSession(),
                                           graphStoreSync: nil,
                                           noteEditViewModel: FakeNoteEditViewModel(),
                                           userDefaults: userDefaults)

        let expectedId = NoteId.testInstance

        testObject.selectNote(id: expectedId)

        XCTAssertEqual(userDefaults.lastSelectedNoteId, expectedId)
    }
    
    func test_selectNote_loadsTheNewNoteInEditorAndShowsIt() {
        let editViewModel = FakeNoteEditViewModel()
        let testObject = NoteListViewModel(noteEditViewModel: editViewModel,
                                           userDefaults: userDefaults)

        let updatedSelectedId = NoteId.testInstance
        testObject.selectNote(id: updatedSelectedId)

        XCTAssertEqual(editViewModel.loadNoteContents_calledCount, 1)
        XCTAssertEqual(editViewModel.loadNoteContents_paramId, updatedSelectedId)
        XCTAssertEqual(testObject.showEditNoteView, true)
    }
    
    func test_noteTextChangedPublished_updatesMetadataList() {
        let editViewModel = FakeNoteEditViewModel()

        let testObject = NoteListViewModel(noteEditViewModel: editViewModel,
                                           userDefaults: userDefaults)

        let previousContents = NoteContents.testInstance
        let previousNoteMeta = NoteMeta(previousContents)

        testObject.noteMetas = [NoteMeta.testInstance,
                                previousNoteMeta,
                                NoteMeta.testInstance ]

        let updatedContents = previousContents.withUpdatedText()
        editViewModel.contentsWithChangedText = updatedContents

        let updatedNoteMeta = NoteMeta(updatedContents,
                                       contentsLastModified: Date.now,
                                       metadataLastModified: Date.now)
        XCTAssertEqual(testObject.noteMetas.count, 3)
        XCTAssertEqual(testObject.noteMetas
            .filter { $0.equalWithinTimeframe(updatedNoteMeta) }
            .count, 1)
    }

    func test_noteBeingEditedPublished_resortsNoteMetasByContentsLastModified() async throws {
        let editViewModel = FakeNoteEditViewModel()
        let testObject = NoteListViewModel(noteEditViewModel: editViewModel,
                                           userDefaults: userDefaults)

        let pastContents = NoteContents.testInstance
        let pastNoteMeta = NoteMeta(pastContents)
            .withUpdatedContentsLastModified(Date.distantPast)
        let nowNoteMeta = NoteMeta(NoteContents.testInstance)
            .withUpdatedContentsLastModified(Date.now)
        let futureNoteMeta = NoteMeta
            .testInstance
            .withUpdatedContentsLastModified(Date.distantFuture)

        testObject.noteMetas = [pastNoteMeta,
                                nowNoteMeta,
                                futureNoteMeta].shuffled()

        try await Task.sleep(nanoseconds: 100)

        let updatedNote = pastContents.withUpdatedText()
        editViewModel.contentsWithChangedText = updatedNote

        let updatedNoteMeta = NoteMeta(updatedNote,
                                       contentsLastModified: Date.now,
                                       metadataLastModified: Date.now)
        let expectedNoteMetas = [futureNoteMeta,
                                 updatedNoteMeta,
                                 nowNoteMeta]

        zip(testObject.noteMetas, expectedNoteMetas)
            .forEach { (actual, expected) in
                XCTAssert(actual.equalWithinTimeframe(expected))
            }
    }
    
    func test_connectToSynchronizerActivity() {
        let graphStoreSync = FakeGraphStoreSync()
        let dispatchQueue = DispatchQueue(label: "test queue")

        let testObject = NoteListViewModel(graphStoreSync: graphStoreSync,
                                           userDefaults: userDefaults,
                                           dispatchQueue: dispatchQueue)
        
        let expectedActivity = SynchronizerActivityStatus.downloading
        graphStoreSync._activityChanged = expectedActivity
        
        dispatchQueue.sync { }
        
        XCTAssertEqual(testObject.syncActivity, expectedActivity)
    }

    func test_noteBeingEditedPublished_updatesUserDefaults() {
        let editViewModel = FakeNoteEditViewModel()

        let testObject = NoteListViewModel(noteEditViewModel: editViewModel,
                                           userDefaults: userDefaults)

        testObject.showEditNoteView = false

        let contents = NoteContents.testInstance
        editViewModel.contentsWithChangedText = contents

        XCTAssertEqual(testObject.showEditNoteView, false)
        XCTAssertEqual(userDefaults.lastSelectedNoteId, contents.id)
    }
}

private extension NoteListViewModel {
    convenience init(userDefaults: UserDefaults) {
        self.init(fileConnector: FakeFileConnector(),
                  shipSession: FakeShipSession(),
                  graphStoreSync: nil,
                  noteEditViewModel: FakeNoteEditViewModel(),
                  userDefaults: userDefaults)
    }
    
    convenience init(shipSession: ShipSessioning,
                     userDefaults: UserDefaults) {
        self.init(fileConnector: FakeFileConnector(),
                  shipSession: shipSession,
                  graphStoreSync: nil,
                  noteEditViewModel: FakeNoteEditViewModel(),
                  userDefaults: userDefaults)
    }
    
    convenience init(fileConnector: FileConnecting,
                     userDefaults: UserDefaults) {
        self.init(fileConnector: fileConnector,
                  shipSession: FakeShipSession(),
                  graphStoreSync: nil,
                  noteEditViewModel: FakeNoteEditViewModel(),
                  userDefaults: userDefaults)
    }
    
    convenience init(fileConnector: FileConnecting,
                     userDefaults: UserDefaults,
                     dispatchQueue: DispatchQueue) {
        self.init(fileConnector: fileConnector,
                  shipSession: FakeShipSession(),
                  graphStoreSync: nil,
                  noteEditViewModel: FakeNoteEditViewModel(),
                  userDefaults: userDefaults,
                  dispatchQueue: dispatchQueue)
    }
    
    convenience init(noteEditViewModel: NoteEditViewModeling,
                     userDefaults: UserDefaults) {
        self.init(fileConnector: FakeFileConnector(),
                  shipSession: FakeShipSession(),
                  graphStoreSync: nil,
                  noteEditViewModel: noteEditViewModel,
                  userDefaults: userDefaults)
    }
            
    convenience init(graphStoreSync: GraphStoreSyncing,
                     userDefaults: UserDefaults) {
        self.init(fileConnector: FakeFileConnector(),
                  shipSession: FakeShipSession(),
                  graphStoreSync: graphStoreSync,
                  noteEditViewModel: FakeNoteEditViewModel(),
                  userDefaults: userDefaults)
    }
    convenience init(graphStoreSync: GraphStoreSyncing,
                     userDefaults: UserDefaults,
                     dispatchQueue: DispatchQueue) {
        self.init(fileConnector: FakeFileConnector(),
                  shipSession: FakeShipSession(),
                  graphStoreSync: graphStoreSync,
                  noteEditViewModel: FakeNoteEditViewModel(),
                  userDefaults: userDefaults,
                  dispatchQueue: dispatchQueue)
    }
    
    convenience init(fileConnector: FileConnecting,
                     shipSession: ShipSessioning,
                     graphStoreSync: GraphStoreSyncing?,
                     noteEditViewModel: NoteEditViewModeling,
                     userDefaults: UserDefaults,
                     dispatchQueue: DispatchQueue = DispatchQueue.main) {
        let appViewModel = FakeAppViewModel()
        appViewModel.fileConnector = fileConnector
        appViewModel.shipSession = shipSession
        appViewModel.graphStoreSync = graphStoreSync
        self.init(appViewModel: appViewModel,
                  noteEditViewModel: noteEditViewModel,
                  userDefaults: userDefaults,
                  dispatchQueue: dispatchQueue)
    }
}

private extension NoteMeta {
    func withUpdatedContentsLastModified(_ contentsLastModified: Date) -> NoteMeta {
        NoteMeta(id: id,
                 title: title,
                 subtitle: subtitle,
                 contentsLastModified: contentsLastModified,
                 metadataLastModified: metadataLastModified,
                 deleted: deleted)
    }
}
