import Foundation
import Combine
import SwiftGraphStore

protocol NoteGraphManaging {
    var graphStoreError: AnyPublisher<GraphStoreError, Never> { get }
    var graphSetupStatusChanged: AnyPublisher<GraphSetupStatus, Never> { get }

    func setupGraph() async throws

    func getNoteStatus(_ keyPath: KeyPath<NoteMeta, Date>,
                       sourceMetadata: NoteMeta,
                       destinationMetadata: NoteMeta?) -> NoteGraphStatus

    func downloadAllIds() async throws -> [NoteId]
    
    func downloadGraphStoreNote(id: NoteId, fileMetadata: NoteMeta?) async throws -> (contents: NoteContents?, metadata: NoteMeta?)
    
    func uploadGraphStoreNote(contents: NoteContents, metadata: NoteMeta) async throws
}
