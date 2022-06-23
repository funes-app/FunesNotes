import Foundation
import Combine
import os

struct NoteSaver {
    private let logger = Logger()
    
    private var fileConnector: FileConnecting
    
    private var cancellables: Set<AnyCancellable> = []
    
    private static let defaultDebounceTime = 2 * 1_000_000_000
    
    init(fileConnector: FileConnecting,
         noteContentsChanged: AnyPublisher<NoteContents, Never>,
         debounceTime: Int = defaultDebounceTime,
         dispatchQueue: DispatchQueue = DispatchQueue.global()) {
        self.fileConnector = fileConnector
        
        noteContentsChanged
            .debounce(for: .nanoseconds(debounceTime),
                      scheduler: dispatchQueue)
            .sink(receiveValue: save)
            .store(in: &cancellables)
    }
    
    func save(contents: NoteContents) {
        logger.debug("Saving contents with id: \(contents.id)")
        
        let modified = Date.now
        let noteMeta = NoteMeta(contents,
                                contentsLastModified: modified,
                                metadataLastModified: modified)
        fileConnector.save(contents: contents, metadata: noteMeta)
    }
}
