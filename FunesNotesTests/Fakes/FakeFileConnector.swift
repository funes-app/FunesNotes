@testable import FunesNotes
import Combine

class FakeFileConnector: ObservableObject, FileConnecting {
    var noteFileManager: NoteFileManaging = FakeNoteFileManager()
    var metadataChangeMonitor: MetadataChangeMonitoring = FakeMetadataChangeMonitor()
        
    var noteDeletedSubject: PassthroughSubject<NoteId, Never> = PassthroughSubject()
    var noteDeleted: AnyPublisher<NoteId, Never> {
        noteDeletedSubject.eraseToAnyPublisher()
    }
    
    var metadataCreatedSubject = PassthroughSubject<NoteMeta, Never>()
    var metadataCreated: AnyPublisher<NoteMeta, Never> {
        metadataCreatedSubject
            .eraseToAnyPublisher()
    }
    var metadataUpdatedSubject = PassthroughSubject<NoteMeta, Never>()
    var metadataUpdated: AnyPublisher<NoteMeta, Never> {
        metadataUpdatedSubject
            .eraseToAnyPublisher()
    }
    
    @Published var _fileError: NoteFileError?
    var fileError: AnyPublisher<NoteFileError, Never> {
        $_fileError
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    var loadNoteContents_calledCount = 0
    var loadNoteContents_paramId: NoteId?
    var loadNoteContents_returnContents: NoteContents?
    func loadNoteContents(id: NoteId) -> NoteContents? {
        loadNoteContents_calledCount += 1
        loadNoteContents_paramId = id
        
        return loadNoteContents_returnContents
    }
    
    var loadNoteMetadata_calledCount = 0
    var loadNoteMetadata_paramId: NoteId?
    var loadNoteMetadata_returnNoteMeta: NoteMeta?
    func loadNoteMetadata(id: NoteId) -> NoteMeta? {
        loadNoteMetadata_calledCount += 1
        loadNoteMetadata_paramId = id
        
        return loadNoteMetadata_returnNoteMeta
    }
    
    var loadNoteMetas_calledCount = 0
    var loadNoteMetas_returnNoteMetas = [NoteMeta]()
    func loadNoteMetas() async -> [NoteMeta] {
        loadNoteMetas_calledCount += 1
        
        return loadNoteMetas_returnNoteMetas
    }
    
    var save_calledCount = 0
    var save_paramContents: NoteContents?
    var save_paramNoteMeta: NoteMeta?
    func save(contents: NoteContents, metadata: NoteMeta) {
        save_calledCount += 1
        save_paramContents = contents
        save_paramNoteMeta = metadata
    }
    
    var delete_calledCount = 0
    var delete_paramId: NoteId?
    func delete(id: NoteId) {
        delete_calledCount += 1
        delete_paramId = id
    }
    
    var deleteAllFiles_calledCount = 0
    func deleteAllFiles() {
        deleteAllFiles_calledCount += 1
    }
    
    var stopMonitor_calledCount = 0
    func stopMonitor() {
        stopMonitor_calledCount += 1
    }
}
