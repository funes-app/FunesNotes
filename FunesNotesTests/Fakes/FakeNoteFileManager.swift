import Foundation
@testable import FunesNotes

class FakeNoteFileManager: NoteFileManaging {
    var loadNoteMetas_calledCount = 0
    var loadNoteMetas_returnedMetas = [NoteMeta]()
    var loadNoteMetas_error: Error?
    func loadNoteMetas() throws -> [NoteMeta] {
        loadNoteMetas_calledCount += 1
        
        if let error = loadNoteMetas_error {
            throw error
        }
        
        return loadNoteMetas_returnedMetas
    }
    
    var loadNoteContents_calledCount = 0
    var loadNoteContents_paramId: NoteId?
    var loadNoteContents_returnContents: NoteContents?
    var loadNoteContents_error: Error?
    func loadNoteContents(id: NoteId) throws -> NoteContents? {
        loadNoteContents_calledCount += 1
        loadNoteContents_paramId = id
        
        if let error = loadNoteContents_error {
            throw error
        }
        
        return loadNoteContents_returnContents
    }
    
    var loadNoteMeta_calledCount = 0
    var loadNoteMeta_paramId: NoteId?
    var loadNoteMeta_returnNoteMeta: NoteMeta?
    var loadNoteMeta_error: Error?
    func loadNoteMeta(id: NoteId) throws -> NoteMeta? {
        loadNoteMeta_calledCount += 1
        loadNoteMeta_paramId = id
        
        if let error = loadNoteMeta_error {
            throw error
        }
        
        return loadNoteMeta_returnNoteMeta
    }
    
    var saveNoteContents_calledCount = 0
    var saveNoteContents_paramContents: NoteContents?
    var saveNoteContents_error: Error?
    func saveNoteContents(_ contents: NoteContents) throws {
        saveNoteContents_calledCount += 1
        saveNoteContents_paramContents = contents
        
        if let error = saveNoteContents_error {
            throw error
        }
    }
    
    var saveNoteMeta_calledCount = 0
    var saveNoteMeta_paramNoteMeta: NoteMeta?
    var saveNoteMeta_error: Error?
    func saveNoteMeta(_ noteMeta: NoteMeta) throws {
        saveNoteMeta_calledCount += 1
        saveNoteMeta_paramNoteMeta = noteMeta
        
        if let error = saveNoteMeta_error {
            throw error
        }
    }
    
    var deleteAllFiles_calledCount = 0
    var deleteAllFiles_error: Error?
    func deleteAllFiles() throws {
        deleteAllFiles_calledCount += 1
        
        if let error = deleteAllFiles_error {
            throw error
        }
    }
}
