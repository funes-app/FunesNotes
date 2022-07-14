@testable import FunesNotes
import Foundation

extension NoteContents {
    static var testInstance: NoteContents {
        return NoteContents(id: NoteId.testInstance,
                    text: UUID().uuidString)
    }
}
