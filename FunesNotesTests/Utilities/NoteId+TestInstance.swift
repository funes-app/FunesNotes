import Foundation
import SwiftGraphStore
@testable import FunesNotes

extension NoteId {
    static var testInstance: NoteId {
        let atom = Atom.testInstance
        return NoteId(atom)
    }
}
