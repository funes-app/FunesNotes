import Foundation
import Combine

protocol MetadataChangeMonitoring {
    var metadataCreated: AnyPublisher<[NoteMeta], Never> { get }
    var metadataUpdated: AnyPublisher<[NoteMeta], Never> { get }
    
    func start()
    func stop()
}
