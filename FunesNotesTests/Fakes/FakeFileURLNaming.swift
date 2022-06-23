import Foundation
@testable import FunesNotes

class FakeFileURLNaming: FileURLNaming {
    var id: NoteId = NoteId.testInstance
    
    static var fileURL_calledCount = 0
    static var fileURL_paramId: NoteId?
    static var fileURL_returnURL: URL?
    static func fileURL(id: NoteId) -> URL {
        fileURL_calledCount += 1
        fileURL_paramId = id
        
        return fileURL_returnURL!
    }
    
    static func idPathComponent(id: NoteId) -> String { "" }
}
