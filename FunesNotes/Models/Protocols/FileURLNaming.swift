import Foundation

protocol FileURLNaming {
    var id: NoteId { get }
    static func idPathComponent(id: NoteId) -> String
    static func fileURL(id: NoteId) -> URL
}

extension FileURLNaming {
    static func fileURL(id: NoteId) -> URL {
        NoteFileManager
            .noteDirectory
            .appendingPathComponent(idPathComponent(id: id))
            .appendingPathExtension("json")
    }
}
