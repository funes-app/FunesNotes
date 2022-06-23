import Foundation

protocol NoteFileManaging {
    func loadNoteContents(id: NoteId) throws -> NoteContents?
    func loadNoteMeta(id: NoteId) throws -> NoteMeta?
    func loadNoteMetas() throws -> [NoteMeta]
    
    func saveNoteContents(_ contents: NoteContents) throws
    func saveNoteMeta(_ noteMeta: NoteMeta) throws
    
    func deleteAllFiles() throws
}
