@testable import FunesNotes
import Foundation

extension NoteContents {
    static var testInstance: NoteContents {
        return NoteContents(id: NoteId.testInstance,
                    text: UUID().uuidString)
    }
    
    func withUpdatedText(_ text: String = UUID().uuidString) -> NoteContents {
        return NoteContents(id: self.id, text: text)
    }
}
