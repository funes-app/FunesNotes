import Foundation
import SwiftGraphStore

extension Index {
    var noteId: NoteId? {
        guard let noteIdAtom = atoms.dropFirst().first else {
            return nil
        }
        
        return NoteId(noteIdAtom)
    }
}
