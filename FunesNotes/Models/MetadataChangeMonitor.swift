import Foundation
import Combine
import os

class MetadataChangeMonitor: MetadataChangeMonitoring {
    enum State {
        case Unstarted
        case Starting
        case Started
    }
    
    private let logger = Logger()
    
    private let metadataCreatedSubject = PassthroughSubject<[NoteMeta], Never>()
    var metadataCreated: AnyPublisher<[NoteMeta], Never> {
        metadataCreatedSubject
            .eraseToAnyPublisher()
    }
    
    private let metadataUpdatedSubject = PassthroughSubject<[NoteMeta], Never>()
    var metadataUpdated: AnyPublisher<[NoteMeta], Never> {
        metadataUpdatedSubject
            .eraseToAnyPublisher()
    }
    
    private let fileManager: NoteFileManaging
    private let directoryChangeMonitor: DirectoryChangeMonitoring
    
    private var currentMetadata = [NoteMeta]()
    
    private var state = State.Unstarted
    
    private var cancellables: Set<AnyCancellable> = Set()

    init(fileManager: NoteFileManaging,
         directoryChangeMonitor: DirectoryChangeMonitoring = DirectoryChangeMonitor()) {
        self.fileManager = fileManager
        self.directoryChangeMonitor = directoryChangeMonitor
        
        directoryChangeMonitor
            .directoryChanged
            .sink(receiveValue: directoryChanged)
            .store(in: &cancellables)
        
        currentMetadata = []
    }
    
    fileprivate func loadMetadata() -> [NoteMeta] {
        do {
            return try fileManager.loadNoteMetas()
        } catch {
            logger.info("Unhandled error loading metadata: \(error.localizedDescription)")
        }
        return []
    }
    
    func start() {
        if state != .Unstarted {
            return
        }
        
        state = .Starting
        
        currentMetadata = loadMetadata()
                
        directoryChangeMonitor.start()
        
        state = .Started
    }
    
    func stop() {
        directoryChangeMonitor.stop()
        
        state = .Unstarted
    }
    
    private func directoryChanged() {
        if state != .Started {
            return
        }
        
        let updatedMetadata = loadMetadata()
                
        let updated = updatedMetadata
            .filter { updated in
                guard let match = metadataWithId(id: updated.id,
                                                 metadataArray: currentMetadata) else {
                    return false
                }
                return match != updated
            }
        
        if !updated.isEmpty {
            logger.debug("Updated metadata: \(updated)")
            metadataUpdatedSubject.send(updated)
        }
        
        let created = updatedMetadata
            .filter { updatedMetadata in
                !currentMetadata.contains { currentMetadata in
                    currentMetadata.id == updatedMetadata.id
                }}
        
        if !created.isEmpty {
            logger.debug("New metadata: \(created)")

            metadataCreatedSubject.send(created)
        }
        
        currentMetadata = updatedMetadata
    }
    
    private func metadataWithId(id: NoteId, metadataArray: [NoteMeta]) -> NoteMeta? {
        metadataArray
            .filter { $0.id == id }
            .first
    }
}
