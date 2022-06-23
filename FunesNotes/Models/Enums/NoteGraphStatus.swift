import Foundation

enum NoteGraphStatus {
    case Missing
    case OutOfDate
    case UpToDate
    case Newer(lastModified: Date)
    case Unknown
}

extension NoteGraphStatus: Equatable {}
