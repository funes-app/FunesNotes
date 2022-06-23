import Foundation
import Combine

protocol DirectoryChangeMonitoring {
    var directoryChanged: AnyPublisher<Void, Never> { get }
    
    func start()
    func stop()
}
