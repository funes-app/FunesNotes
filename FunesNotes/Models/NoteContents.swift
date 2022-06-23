import Foundation


struct NoteContents {
    let id: NoteId
    var text: String
    
    init(id: NoteId = NoteId(date: Date.now),
         text: String = "") {
        self.id = id
        self.text = text
    }
}

extension NoteContents: Codable {}

extension NoteContents: Equatable {}

extension NoteContents: Identifiable {}

extension NoteContents: FileURLNaming {
    static func idPathComponent(id: NoteId) -> String {
        id.description
    }
}

extension NoteContents {
    static var empty: NoteContents {
        NoteContents(id: NoteId.empty)
    }
    
    var isEmpty: Bool {
        self.id == NoteId.empty
    }
}
