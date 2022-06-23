import Foundation
@testable import FunesNotes
import XCTest

extension NoteMeta {
    init(_ contents: NoteContents) {
        self.init(contents,
                  contentsLastModified: Date.now,
                  metadataLastModified: Date.now)
    }
    
    static var testInstance: NoteMeta {
        NoteMeta(NoteContents.testInstance)
    }
  
    func equalWithinTimeframe(_ noteMeta: NoteMeta, dateAccuracy: TimeInterval = 10) -> Bool {
        self.id == noteMeta.id &&
        self.title == noteMeta.title &&
        self.subtitle == noteMeta.subtitle &&
        abs(self.contentsLastModified.timeIntervalSince(noteMeta.contentsLastModified)) <= dateAccuracy &&
        abs(self.metadataLastModified.timeIntervalSince(noteMeta.metadataLastModified)) <= dateAccuracy
    }
}
