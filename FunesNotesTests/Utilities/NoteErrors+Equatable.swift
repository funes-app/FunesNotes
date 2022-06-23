import Foundation
@testable import FunesNotes

extension NoteFileError: Equatable {
    public static func == (lhs: NoteFileError, rhs: NoteFileError) -> Bool {
        switch (lhs, rhs) {
        case (.loadFailure, .loadFailure):
            return lhs.internalError == rhs.internalError
        case (.deleteFailure, .deleteFailure):
            return lhs.internalError == rhs.internalError
        case (.saveFailure, .saveFailure):
            return lhs.internalError == rhs.internalError
        default:
            return false
        }
    }
}
