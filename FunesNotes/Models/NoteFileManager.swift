import Foundation
import os

struct NoteFileManager: NoteFileManaging {
    internal typealias FileURLCodable = FileURLNaming & Codable
    internal typealias ItemDecoder<T: FileURLCodable> = (URL) throws -> T
    
    private let logger = Logger()
    
    static var noteDirectory: URL {
        try! FileManager.default
            .url(for: .documentDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: false)
    }
    
    func loadNoteMetas() throws -> [NoteMeta] {
        return try loadNoteMetas(contentsOfDirectory: contentsOfDirectory,
                                 decoder: { try .init($0) })
    }
    
    internal func loadNoteMetas(contentsOfDirectory: (URL) throws -> [URL],
                                decoder: (URL) throws -> NoteMeta) throws -> [NoteMeta] {
        do {
            return try contentsOfDirectory(NoteFileManager.noteDirectory)
                .filter { NoteMeta.isNoteMetaFile($0) }
                .map(decoder)
        } catch {
            logger.log("Error loading metadata files:\(error.localizedDescription)")
            throw NoteFileError.loadFailure(error: error)
        }
    }
    
    func loadNoteContents(id: NoteId) throws -> NoteContents? {
        try loadNoteContents(id: id,
                             decoder: { try .init($0) })
    }
    
    internal func loadNoteContents(id: NoteId,
                                   decoder: ItemDecoder<NoteContents> ) throws -> NoteContents? {
        guard let contents: NoteContents = try loadItem(id: id) else {
            return nil
        }
        
        return contents
    }
    
    func loadNoteMeta(id: NoteId) throws -> NoteMeta? {
        try loadItem(id: id)
    }
    
    internal func loadItem<T: FileURLCodable>(id: NoteId,
                                              decoder: ItemDecoder<T> = { try .init($0) }) throws -> T? {
        do {
            let fileURL = T.fileURL(id: id)
            return try decoder(fileURL)
        }  catch CocoaError.fileReadNoSuchFile {
            logger.log("No file for ID \(id), ignoring")
            return nil
        } catch {
            logger.log("Error loading item ID \(id):\(error.localizedDescription)")
            throw NoteFileError.loadFailure(error: error)
        }
    }
    
    func saveNoteContents(_ note: NoteContents) throws {
        logger.debug("Saving note contents with id \(note.id)")
        try saveItem(item: note)
    }
    
    func saveNoteMeta(_ noteMeta: NoteMeta) throws {
        logger.debug("Saving metadata: \(noteMeta.title ?? "")")
        try saveItem(item: noteMeta)
    }
    
    internal func saveItem<T: FileURLCodable>(item: T,
                                              encoder: (T, URL) throws -> Void = { try $0.writeToFile($1) }) throws
    {
        let fileURL = T.fileURL(id: item.id)
        
        do {
            try encoder(item, fileURL)
        } catch {
            logger.log("Error saving item ID \(item.id):\(error.localizedDescription)")
            throw NoteFileError.saveFailure(error: error)
        }
    }
    
    func deleteAllFiles() throws {
        try deleteAllFiles(contentsOfDirectory: contentsOfDirectory)
    }

    internal func deleteAllFiles(contentsOfDirectory: (URL) throws -> [URL],
                                 removeFile: (URL) throws -> Void = FileManager.default.removeItem) throws {
        try contentsOfDirectory(NoteFileManager.noteDirectory)
            .forEach(removeFile)
    }

    internal func contentsOfDirectory(dir: URL) throws -> [URL] {
        try FileManager.default
            .contentsOfDirectory(at: dir,
                                 includingPropertiesForKeys: nil,
                                 options: .skipsHiddenFiles)
    }
}
