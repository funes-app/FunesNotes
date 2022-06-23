import Foundation
import Combine
@testable import FunesNotes

class FakeDirectoryChangeMonitor: DirectoryChangeMonitoring {
    let directoryChangedSubject = PassthroughSubject<Void, Never>()
    var directoryChanged: AnyPublisher<Void, Never> {
        directoryChangedSubject
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

