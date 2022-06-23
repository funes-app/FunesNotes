import Foundation
import Combine
import UIKit
import os

class GraphStoreSync: GraphStoreSyncing {
    private let logger = Logger()
    
    @Published private var _fileError: NoteFileError?
    var fileError: AnyPublisher<NoteFileError, Never> {
        $_fileError
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    @Published private var _graphStoreError: GraphStoreError?
    var graphStoreError: AnyPublisher<GraphStoreError, Never> {
        $_graphStoreError
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    @Published private var _activityChanged = SynchronizerActivityStatus.idle
    var activityChanged: AnyPublisher<SynchronizerActivityStatus, Never> {
        $_activityChanged
            .eraseToAnyPublisher()
    }

    let fileManager: NoteFileManaging
    let graphManager: NoteGraphManaging
    let metadataMonitor: MetadataChangeMonitoring
        
    private var cancellables: Set<AnyCancellable> = Set()
    
    init(fileManager: NoteFileManaging,
         graphManager: NoteGraphManaging,
         metadataMonitor: MetadataChangeMonitoring) {
        self.fileManager = fileManager
        self.graphManager = graphManager
        self.metadataMonitor = metadataMonitor
            
        metadataMonitor
            .metadataCreated
            .sink(receiveValue: { [weak self] in
                self?.uploadChanges(metadatas: $0)
            })
            .store(in: &cancellables)
        
        metadataMonitor
            .metadataUpdated
            .sink(receiveValue: { [weak self] in
                self?.uploadChanges(metadatas: $0)
            })
            .store(in: &cancellables)
    }
    
    func start() {
        metadataMonitor.start()
    }
    
    private func uploadChanges(metadatas: [NoteMeta]) {
        let group = DispatchGroup()
        group.enter()

        Task {
            for metadata in metadatas {
                _activityChanged = .uploading
                let _ = await loadContentsAndUpload(metadata)
                _activityChanged = .idle
            }
            group.leave()
        }
        
        group.wait()
    }
    
    func synchronize() async {
        await downloadAll()
        await uploadAll()
    }
    
    func uploadAll() async {
        logger.debug("Uploading all files.")
        _activityChanged = .uploading

        let metadatas: [NoteMeta]
        do {
            metadatas = try fileManager.loadNoteMetas()
        }  catch let error as NoteFileError {
            _fileError = error
            _activityChanged = .idle
            return
        } catch {
            logger.debug("Unexpected exception trying to upload all notes")
            _activityChanged = .idle
            return
        }
                    
        for metadata in metadatas {
            if !(await loadContentsAndUpload(metadata)) {
                return
            }
        }
        
        _activityChanged = .idle
    }
    
    private func loadContentsAndUpload(_ metadata: NoteMeta) async -> Bool {
        logger.debug("Uploading note \(metadata.id)")
        
        do {
            guard let contents = try fileManager.loadNoteContents(id: metadata.id) else {
                return false
            }
            
            try await graphManager.uploadGraphStoreNote(contents: contents,
                                                        metadata: metadata)
            return true
        } catch GraphStoreSaveError.graphStoreVersionIsNewer {
            logger.debug("Graph store version for \(metadata.id) is newer. Skipping")
        } catch let error as GraphStoreReadError {
            _graphStoreError = GraphStoreError.readError(error: error)
        } catch let error as GraphStoreSaveError {
            _graphStoreError = GraphStoreError.saveError(error: error)
        } catch let error as NoteFileError {
            _fileError = error
        }
        catch {
            logger.debug("Unhandled exception trying to upload all notes")
        }
        return false
    }
    
    func downloadAll() async {
        logger.debug("Downloading all files.")
        do {
            _activityChanged = .downloading
            
            let ids = try await graphManager.downloadAllIds()
            
            for id in ids {
                let fileMetadata = try fileManager.loadNoteMeta(id: id)

                let (contents, metadata) = try await graphManager.downloadGraphStoreNote(id: id,
                                                                                         fileMetadata: fileMetadata)
                
                if let contents = contents {
                    try fileManager.saveNoteContents(contents)
                }
                
                if let metadata = metadata {
                    var contents = contents
                    if contents == nil {
                        contents = try fileManager.loadNoteContents(id: id)
                    }

                    if let contents = contents {
                        let savedMetadata = NoteMeta(contents: contents,
                                                     metadata: metadata)
                        try fileManager.saveNoteMeta(savedMetadata)
                    }
                }
            }
        } catch let error as NoteFileError {
            _fileError = error
        } catch let error as GraphStoreReadError {
            _graphStoreError = GraphStoreError.readError(error: error)
        } catch {
            logger.debug("Unhandled exception trying to download all notes")
        }
        
        _activityChanged = .idle
    }
    
}
