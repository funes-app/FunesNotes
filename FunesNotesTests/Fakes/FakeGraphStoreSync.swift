import Foundation
import Combine
@testable import FunesNotes

class FakeGraphStoreSync: GraphStoreSyncing {
    @Published var _fileError: NoteFileError?
    var fileError: AnyPublisher<NoteFileError, Never> {
        $_fileError
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    @Published var _graphStoreError: GraphStoreError?
    var graphStoreError: AnyPublisher<GraphStoreError, Never> {
        $_graphStoreError
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    @Published var _activityChanged = SynchronizerActivityStatus.idle
    var activityChanged: AnyPublisher<SynchronizerActivityStatus, Never> {
        $_activityChanged
            .eraseToAnyPublisher()
    }
    
    var start_calledCount = 0
    func start() {
        start_calledCount += 1
    }
    
    var synchronize_calledCount = 0
    func synchronize() async {
        synchronize_calledCount += 1
    }
    
    var uploadAll_calledCount = 0
    func uploadAll() async {
        uploadAll_calledCount += 1
    }
    
    var downloadAll_calledCount = 0
    func downloadAll() async {
        downloadAll_calledCount += 1
    }
}
