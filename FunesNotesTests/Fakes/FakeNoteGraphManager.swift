import Foundation
import Combine
import SwiftGraphStore
@testable import FunesNotes

class FakeNoteGraphManager: NoteGraphManaging {
    @Published var _graphStoreError: GraphStoreError?
    var graphStoreError: AnyPublisher<GraphStoreError, Never> {
        $_graphStoreError
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    @Published var _graphSetupStatusChanged: GraphSetupStatus?
    var graphSetupStatusChanged: AnyPublisher<GraphSetupStatus, Never> {
        $_graphSetupStatusChanged
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    var setupGraph_calledCount = 0
    var setupGraph_error: Error?
    func setupGraph() async throws {
        setupGraph_calledCount += 1
        
        if let error = setupGraph_error {
            throw error
        }
    }
    
    var downloadAllIds_calledCount = 0
    var downloadAllIds_error: GraphStoreReadError?
    var downloadAllIds_returnIds = [NoteId]()
    func downloadAllIds() async throws -> [NoteId] {
        downloadAllIds_calledCount += 1
        
        if let error = downloadAllIds_error {
            throw error
        } else {
            return downloadAllIds_returnIds
        }
    }
    
    var downloadGraphStoreNote_calledCount = 0
    var downloadGraphStoreNote_paramFileMetadata: NoteMeta?
    var downloadGraphStoreNote_error: Error?
    var downloadGraphStoreNote_returnContents: NoteContents?
    var downloadGraphStoreNote_returnMetadata: NoteMeta?
    func downloadGraphStoreNote(id: NoteId, fileMetadata: NoteMeta?) async throws -> (contents: NoteContents?, metadata: NoteMeta?) {

        downloadGraphStoreNote_calledCount += 1
        downloadGraphStoreNote_paramFileMetadata = fileMetadata
        
        if let error = downloadGraphStoreNote_error {
            throw error
        } else {
            return (downloadGraphStoreNote_returnContents,
                    downloadGraphStoreNote_returnMetadata)
        }
    }

    var getNoteStatus_calledCount = 0
    var getNoteStatus_paramKeyPath: KeyPath<NoteMeta, Date>?
    var getNoteStatus_paramSourceMetadata: NoteMeta?
    var getNoteStatus_paramDestinationMetadata: NoteMeta?
    var getNoteStatus_returnStatus = NoteGraphStatus.Unknown
    func getNoteStatus(_ keyPath: KeyPath<NoteMeta, Date>,
                       sourceMetadata: NoteMeta,
                       destinationMetadata: NoteMeta?) -> NoteGraphStatus {
        getNoteStatus_calledCount += 1
        getNoteStatus_paramKeyPath = keyPath
        getNoteStatus_paramSourceMetadata = sourceMetadata
        getNoteStatus_paramDestinationMetadata = destinationMetadata
        
        return getNoteStatus_returnStatus
    }
    
    var uploadGraphStoreNote_calledCount = 0
    var uploadGraphStoreNote_paramContents: NoteContents?
    var uploadGraphStoreNote_paramNoteMeta: NoteMeta?
    var uploadGraphStoreNote_error: Error?
    func uploadGraphStoreNote(contents: NoteContents, metadata: NoteMeta) async throws {
        uploadGraphStoreNote_calledCount += 1
        uploadGraphStoreNote_paramContents = contents
        uploadGraphStoreNote_paramNoteMeta = metadata
        
        if let error = uploadGraphStoreNote_error {
            throw error
        }
    }
}
