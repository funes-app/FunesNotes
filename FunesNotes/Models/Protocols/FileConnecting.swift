import Combine

protocol FileConnecting {
    var noteFileManager: NoteFileManaging { get }
    var metadataChangeMonitor: MetadataChangeMonitoring { get }

    var fileError: AnyPublisher<NoteFileError, Never> { get }
    
    var noteDeleted: AnyPublisher<NoteId, Never> { get }
    var metadataCreated: AnyPublisher<NoteMeta, Never> { get }
    var metadataUpdated: AnyPublisher<NoteMeta, Never> { get }
    
    func loadNoteContents(id: NoteId) -> NoteContents?
    func loadNoteMetadata(id: NoteId) -> NoteMeta?
    func loadNoteMetas() async -> [NoteMeta]
    func save(contents: NoteContents, metadata: NoteMeta)
    func delete(id: NoteId)
    
    func deleteAllFiles()
    
    func stopMonitor()
}
