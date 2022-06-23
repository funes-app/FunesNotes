import Foundation
import Combine
@testable import FunesNotes

class FakeNoteGraphConnector: NoteGraphConnecting {
    var graphManager: NoteGraphManaging = FakeNoteGraphManager()
    
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
    func setupGraph() async {
        setupGraph_calledCount += 1
    }
    
    var downloadAllIds_calledCount = 0
    var downloadAllIds_returnIds: [NoteId]?
    func downloadAllIds() async -> [NoteId] {
        downloadAllIds_calledCount += 1
        
        return downloadAllIds_returnIds!
    }
    
    var uploadGraphStoreNote_calledCount = 0
    var uploadGraphStoreNote_paramContents: NoteContents?
    var uploadGraphStoreNote_paramMetadata: NoteMeta?
    func uploadGraphStoreNote(contents: NoteContents, metadata: NoteMeta) async {
        uploadGraphStoreNote_calledCount += 1
        uploadGraphStoreNote_paramContents = contents
        uploadGraphStoreNote_paramMetadata = metadata
    }
}
