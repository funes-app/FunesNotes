import Foundation
import Combine

protocol GraphStoreSyncing {
    var fileError: AnyPublisher<NoteFileError, Never> { get }
    var graphStoreError: AnyPublisher<GraphStoreError, Never> { get }
    
    var activityChanged: AnyPublisher<SynchronizerActivityStatus, Never> { get }

    func start()
    
    func synchronize() async
    func downloadAll() async
    func uploadAll() async
}
