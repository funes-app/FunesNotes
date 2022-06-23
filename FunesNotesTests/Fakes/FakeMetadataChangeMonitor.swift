import Foundation
import Combine
@testable import FunesNotes

class FakeMetadataChangeMonitor: MetadataChangeMonitoring {
    let metadataCreatedSubject = PassthroughSubject<[NoteMeta], Never>()
    var metadataCreated: AnyPublisher<[NoteMeta], Never> {
        metadataCreatedSubject
            .eraseToAnyPublisher()
    }
    
    let metadataUpdatedSubject = PassthroughSubject<[NoteMeta], Never>()
    var metadataUpdated: AnyPublisher<[NoteMeta], Never> {
        metadataUpdatedSubject
            .eraseToAnyPublisher()
    }
    
    var start_calledCount = 0
    func start() {
        start_calledCount += 1
    }
    
    var stop_calledCount = 0
    func stop() {
        stop_calledCount += 1
    }
}
