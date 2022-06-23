import Foundation
import Combine

protocol NoteGraphConnecting {
    var graphManager: NoteGraphManaging { get }
    
    var graphStoreError: AnyPublisher<GraphStoreError, Never> { get }
    var graphSetupStatusChanged: AnyPublisher<GraphSetupStatus, Never> { get }

    func setupGraph() async

    func downloadAllIds() async -> [NoteId]

    func uploadGraphStoreNote(contents: NoteContents, metadata: NoteMeta) async
}
