import Foundation
import Combine

class PreviewGraphStoreSync: GraphStoreSyncing {
    var fileError: AnyPublisher<NoteFileError, Never> = Empty().eraseToAnyPublisher()
    var graphStoreError: AnyPublisher<GraphStoreError, Never> = Empty().eraseToAnyPublisher()
    
    @Published var _activityChanged = SynchronizerActivityStatus.idle
    var activityChanged: AnyPublisher<SynchronizerActivityStatus, Never>{
        $_activityChanged
            .eraseToAnyPublisher()
    }
    
    func start() {}
    func synchronize() async {}
    func uploadAll() async {}
    func downloadAll() async {}
}
