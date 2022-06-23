import Foundation
import SwiftUI
import Combine
import os

class FileConnector: ObservableObject, FileConnecting {
    private let logger = Logger()
    
    private let noteDeletedSubject = PassthroughSubject<NoteId, Never>()
    var noteDeleted: AnyPublisher<NoteId, Never> {
        noteDeletedSubject
            .eraseToAnyPublisher()
    }
    
    private let metadataCreatedSubject = PassthroughSubject<NoteMeta, Never>()
    var metadataCreated: AnyPublisher<NoteMeta, Never> {
        metadataCreatedSubject
            .eraseToAnyPublisher()
    }
    
    private let metadataUpdatedSubject = PassthroughSubject<NoteMeta, Never>()
    var metadataUpdated: AnyPublisher<NoteMeta, Never>  {
        metadataUpdatedSubject
            .eraseToAnyPublisher()
    }
    
    @Published var _fileError: NoteFileError?
    var fileError: AnyPublisher<NoteFileError, Never> {
        $_fileError
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    let noteFileManager: NoteFileManaging
    let metadataChangeMonitor: MetadataChangeMonitoring
    
    private var cancellables = Set<AnyCancellable>()
    
    convenience init() {
        let noteFileManager = NoteFileManager()
        let metadataChangeMonitor = MetadataChangeMonitor(fileManager: noteFileManager)
        
        self.init(noteFileManager: noteFileManager,
                  metadataChangeMonitor: metadataChangeMonitor)
    }
    
    init(noteFileManager: NoteFileManaging,
         metadataChangeMonitor: MetadataChangeMonitoring) {
        self.noteFileManager = noteFileManager
        self.metadataChangeMonitor = metadataChangeMonitor
        
        metadataChangeMonitor
            .metadataUpdated
            .sink(receiveValue: { [weak self] in
                self?.handleUpdatedMetadata($0)
            })
            .store(in: &cancellables)
        
        metadataChangeMonitor
            .metadataCreated
            .sink(receiveValue: { [weak self] in
                self?.handleCreatedMetadata($0)
            })
            .store(in: &cancellables)

        startMonitor()
    }
    
    private func startMonitor() {
        Task { [weak self] in
            self?.metadataChangeMonitor.start()
        }
    }
    
    func stopMonitor() {
        metadataChangeMonitor.stop()
    }
    
    func loadNoteContents(id: NoteId) -> NoteContents? {
        do {
            return try self.noteFileManager.loadNoteContents(id: id)
        } catch NoteFileError.loadFailure(let error) {
            _fileError = .loadFailure(error: error)
        } catch {
            logger.info("Unhandled exception loading note contents: \(error.localizedDescription)")
        }
        return nil
    }
    
    func loadNoteMetadata(id: NoteId) -> NoteMeta? {
        do {
            return try self.noteFileManager.loadNoteMeta(id: id)
        } catch NoteFileError.loadFailure(let error) {
            _fileError = .loadFailure(error: error)
        } catch {
            logger.info("Unhandled exception loading note contents: \(error.localizedDescription)")
        }
        return nil
    }
        
    @MainActor
    func loadNoteMetas() async -> [NoteMeta] {
        do {
            return try await doLoadNoteMetas()
        } catch NoteFileError.loadFailure(let error) {
            _fileError = .loadFailure(error: error)
        } catch {
            logger.info("Unhandled exception loading all metadata: \(error.localizedDescription)")
        }
        
        return []        
    }
    
    private func doLoadNoteMetas() async throws -> [NoteMeta] {
        try await withCheckedThrowingContinuation({ continuation in
            do {
                let noteMetas = try noteFileManager.loadNoteMetas()
                continuation.resume(returning: noteMetas)
            } catch {
                continuation.resume(throwing: error)
            }
        })
    }

    func save(contents: NoteContents, metadata: NoteMeta) {
        do {
            try noteFileManager.saveNoteContents(contents)
            try noteFileManager.saveNoteMeta(metadata)
        } catch NoteFileError.saveFailure(let error) {
            _fileError = .saveFailure(error: error)
        } catch {
            logger.info("Unhandled exception saving a note: \(error.localizedDescription)")
        }
    }
    
    func delete(id: NoteId) {
        do {
            if let noteMeta = try noteFileManager.loadNoteMeta(id: id) {
                let deleted = noteMeta
                    .withDeleted(true)
                    .withMetadataLastModified(.now)
                try noteFileManager.saveNoteMeta(deleted)
            } else {
                logger.info("Attempting to delete id \(id): Metadata not found.  Ignoring...")
            }

        } catch NoteFileError.loadFailure(let error) {
            _fileError = .deleteFailure(error: error)
        } catch NoteFileError.saveFailure(let error) {
            _fileError = .deleteFailure(error: error)
        } catch {
        }
    }
    
    func deleteAllFiles() {
        logger.debug("Removing all files in \(NoteFileManager.noteDirectory)")
        do {
            try noteFileManager.deleteAllFiles()
        } catch {
            _fileError = .deleteFailure(error: error)
        }
    }
    
    private func handleCreatedMetadata(_ createdMetadata: [NoteMeta]) {
        createdMetadata.forEach { [weak self] in
            self?.metadataCreatedSubject.send($0)
        }
    }
    
    private func handleUpdatedMetadata(_ updatedMetadata: [NoteMeta]) {
        for metadata in updatedMetadata {
            if metadata.deleted {
                noteDeletedSubject.send(metadata.id)
            } else {
                metadataUpdatedSubject.send(metadata)
            }
        }
    }
}
