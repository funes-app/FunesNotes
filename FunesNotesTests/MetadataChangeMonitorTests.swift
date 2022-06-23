import XCTest
@testable import FunesNotes

class MetadataChangeMonitorTests: XCTestCase {
    func test_start_loadsMetadata() throws {
        let fileManager = FakeNoteFileManager()
        
        let testObject = MetadataChangeMonitor(fileManager: fileManager,
                                               directoryChangeMonitor: FakeDirectoryChangeMonitor())
        
        testObject.start()
        XCTAssertEqual(fileManager.loadNoteMetas_calledCount, 1)
    }
    
    func test_start_startsDirectoryMonitor() throws {
        let fileManager = FakeNoteFileManager()
        let directoryChangeMonitor = FakeDirectoryChangeMonitor()
        
        let testObject = MetadataChangeMonitor(fileManager: fileManager,
                                               directoryChangeMonitor: directoryChangeMonitor)
        
        testObject.start()
        XCTAssertEqual(directoryChangeMonitor.start_calledCount, 1)
    }
    
    func test_start_subsequentCallsAreIgnored() throws {
        let fileManager = FakeNoteFileManager()
        let directoryChangeMonitor = FakeDirectoryChangeMonitor()
        
        let testObject = MetadataChangeMonitor(fileManager: fileManager,
                                               directoryChangeMonitor: directoryChangeMonitor)
        
        testObject.start()
        testObject.start()
        testObject.start()

        XCTAssertEqual(directoryChangeMonitor.start_calledCount, 1)
    }
    
    func test_stop_stopsDirectoryMonitor() throws {
        let fileManager = FakeNoteFileManager()
        let directoryChangeMonitor = FakeDirectoryChangeMonitor()
        
        let testObject = MetadataChangeMonitor(fileManager: fileManager,
                                               directoryChangeMonitor: directoryChangeMonitor)
        
        testObject.stop()
        XCTAssertEqual(directoryChangeMonitor.stop_calledCount, 1)
    }
    
    func test_whenDirectoryChanges_whenNotStarted_doesNotUpdateMetadata() throws {
        let fileManager = FakeNoteFileManager()
        let directoryChangeMonitor = FakeDirectoryChangeMonitor()
        
        let _ = MetadataChangeMonitor(fileManager: fileManager,
                                               directoryChangeMonitor: directoryChangeMonitor)
        
        directoryChangeMonitor.directoryChangedSubject.send()
        XCTAssertEqual(fileManager.loadNoteMetas_calledCount, 0)
    }
    
    func test_whenDirectoryChanges_whenStarted_updatesMetadata() throws {
        let fileManager = FakeNoteFileManager()
        let directoryChangeMonitor = FakeDirectoryChangeMonitor()
        
        let testObject = MetadataChangeMonitor(fileManager: fileManager,
                                               directoryChangeMonitor: directoryChangeMonitor)
        
        testObject.start()
        XCTAssertEqual(fileManager.loadNoteMetas_calledCount, 1)
        
        directoryChangeMonitor.directoryChangedSubject.send()
        XCTAssertEqual(fileManager.loadNoteMetas_calledCount, 2)
    }
    
    func test_whenDirectoryChanges_whenStopped_doesNotUpdateMetadata() throws {
        let fileManager = FakeNoteFileManager()
        let directoryChangeMonitor = FakeDirectoryChangeMonitor()
        
        let testObject = MetadataChangeMonitor(fileManager: fileManager,
                                               directoryChangeMonitor: directoryChangeMonitor)
        
        testObject.start()
        XCTAssertEqual(fileManager.loadNoteMetas_calledCount, 1)
        
        testObject.stop()
        
        directoryChangeMonitor.directoryChangedSubject.send()
        XCTAssertEqual(fileManager.loadNoteMetas_calledCount, 1)
    }
    
    func test_whenDirectoryChanges_publishesUpdates() async throws {
        let fileManager = FakeNoteFileManager()
        let directoryChangeMonitor = FakeDirectoryChangeMonitor()
        
        let testObject = MetadataChangeMonitor(fileManager: fileManager,
                                               directoryChangeMonitor: directoryChangeMonitor)
        let contents = NoteContents.testInstance
        let initialMetadata = NoteMeta(contents).withDeleted(false)
        fileManager.loadNoteMetas_returnedMetas = [initialMetadata]
        
        testObject.start()
        
        let updatedMetadata = initialMetadata.withDeleted(true)
        fileManager.loadNoteMetas_returnedMetas = [updatedMetadata]
        
        let returnedMetadata = try await waitForResult(testObject
            .metadataUpdated) {
                directoryChangeMonitor.directoryChangedSubject.send()
                
            }
        
        XCTAssertEqual(returnedMetadata, [updatedMetadata])
    }
    
    func test_whenNoChanges_doesNotPublish() async throws {
        let fileManager = FakeNoteFileManager()
        let directoryChangeMonitor = FakeDirectoryChangeMonitor()
        
        let testObject = MetadataChangeMonitor(fileManager: fileManager,
                                               directoryChangeMonitor: directoryChangeMonitor)
        let metadata = (0...10).map { _ in NoteMeta.testInstance }
        fileManager.loadNoteMetas_returnedMetas = metadata.shuffled()
        
        testObject.start()
        
        fileManager.loadNoteMetas_returnedMetas = metadata.shuffled()
        
        try await waitForNoResult(testObject.metadataUpdated) {
            directoryChangeMonitor.directoryChangedSubject.send()
        }
    }
    
    func test_whenMetadataAdded_publishesUpdates() async throws {
        let fileManager = FakeNoteFileManager()
        let directoryChangeMonitor = FakeDirectoryChangeMonitor()
        
        let testObject = MetadataChangeMonitor(fileManager: fileManager,
                                               directoryChangeMonitor: directoryChangeMonitor)
        let otherMetadata = (0...10).map { _ in NoteMeta.testInstance }
        fileManager.loadNoteMetas_returnedMetas = otherMetadata
        
        testObject.start()
        
        let newMetadata = (0...5).map { _ in NoteMeta.testInstance }
        let updatedMetadata = (otherMetadata + newMetadata).shuffled()
        fileManager.loadNoteMetas_returnedMetas = updatedMetadata
        
        let createdMetadata = try await waitForResult(testObject.metadataCreated) {
            directoryChangeMonitor.directoryChangedSubject.send()
        }
        
        XCTAssertEqual(Set(createdMetadata), Set(newMetadata))
    }
    
    func test_whenNoAdditions_doesNotPublish() async throws {
        let fileManager = FakeNoteFileManager()
        let directoryChangeMonitor = FakeDirectoryChangeMonitor()
        
        let testObject = MetadataChangeMonitor(fileManager: fileManager,
                                               directoryChangeMonitor: directoryChangeMonitor)
        let metadata = (0...10).map { _ in NoteMeta.testInstance }
        fileManager.loadNoteMetas_returnedMetas = metadata.shuffled()
        
        testObject.start()
        
        fileManager.loadNoteMetas_returnedMetas = metadata.shuffled()
        
        try await waitForNoResult(testObject.metadataCreated) {
            directoryChangeMonitor.directoryChangedSubject.send()
        }
    }
    
    func test_whenDirectoryChanges_updatesCurrentMetadata() async throws {
        let fileManager = FakeNoteFileManager()
        let directoryChangeMonitor = FakeDirectoryChangeMonitor()
        
        let testObject = MetadataChangeMonitor(fileManager: fileManager,
                                               directoryChangeMonitor: directoryChangeMonitor)
        let contents = NoteContents.testInstance
        let initialMetadata = NoteMeta(contents).withDeleted(false)
        fileManager.loadNoteMetas_returnedMetas = [initialMetadata]
        
        testObject.start()
        
        let updatedMetadata = initialMetadata.withDeleted(true)
        fileManager.loadNoteMetas_returnedMetas = [updatedMetadata]
        
        let _ = try await waitForResult(testObject
            .metadataUpdated) {
                directoryChangeMonitor.directoryChangedSubject.send()
                
            }
        
        fileManager.loadNoteMetas_returnedMetas = [updatedMetadata]
        
        try await waitForNoResult(testObject.metadataUpdated) {
            directoryChangeMonitor.directoryChangedSubject.send()
        }
    }
}
