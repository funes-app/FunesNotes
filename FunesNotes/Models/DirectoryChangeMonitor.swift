import Foundation
import Combine
import os

// The contents were shamelessly pilfered from here, with some modifications:
// https://medium.com/over-engineering/monitoring-a-folder-for-changes-in-ios-dc3f8614f902
class DirectoryChangeMonitor: DirectoryChangeMonitoring {
    private let logger = Logger()
    
    private let directoryChangedSubject = PassthroughSubject<Void, Never>()
    var directoryChanged: AnyPublisher<Void, Never> {
        directoryChangedSubject
            .eraseToAnyPublisher()
    }

    private var monitoredDirectoryFileDescriptor: CInt = -1
    
    private let directoryMonitorQueue = DispatchQueue(label: "DirectoryMonitorQueue", attributes: .concurrent)
    
    private var directoryMonitorSource: DispatchSourceFileSystemObject?
    
    let url: URL
    init(url: URL = NoteFileManager.noteDirectory) {
        self.url = url
    }
    
    func start() {
        guard directoryMonitorSource == nil && monitoredDirectoryFileDescriptor == -1 else {
            return
        }
        
        monitoredDirectoryFileDescriptor = open(url.path, O_EVTONLY)
        
        let eventMask = DispatchSource.FileSystemEvent.write
        directoryMonitorSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: monitoredDirectoryFileDescriptor, eventMask: eventMask, queue: directoryMonitorQueue)
        
        directoryMonitorSource?.setEventHandler { [weak self] in
            self?.logger.debug("Update in documents directory")
            self?.directoryChangedSubject.send()
        }
        
        directoryMonitorSource?.setCancelHandler { [weak self] in
            guard let strongSelf = self else { return }
            close(strongSelf.monitoredDirectoryFileDescriptor)
            strongSelf.monitoredDirectoryFileDescriptor = -1
            strongSelf.directoryMonitorSource = nil
        }

        directoryMonitorSource?.resume()
    }

    func stop() {
        directoryMonitorSource?.cancel()
    }
}
