import XCTest
@testable import FunesNotes

class NoteFileManagerTests: XCTestCase {
    func test_loadItem_decodesFileAtURLAndReturnsNote() throws {
        let expectedContents = NoteContents.testInstance
        
        var decoder_paramFileURL: URL?
        func decoderStub(fileURL: URL) -> NoteContents {
            decoder_paramFileURL = fileURL
            
            return expectedContents
        }
        
        let testObject = NoteFileManager()
        
        let id = NoteId.testInstance
        let fileURL = NoteContents.fileURL(id: id)
        
        let contents = try testObject.loadItem(id: id,
                                           decoder: decoderStub)
        
        XCTAssertEqual(decoder_paramFileURL, fileURL)
        XCTAssertEqual(contents, expectedContents)
    }
    
    func test_loadItem_throwsExceptionFromDecoder() throws {
        let readError = NSError(domain: "", code: 0)
        
        func errorDecoder(url: URL) throws -> NoteContents {
            throw readError
        }
        
        let expectedError = NoteFileError.loadFailure(error: readError)
        
        let testObject = NoteFileManager()
        
        do {
            let _ = try testObject.loadItem(id: NoteId.testInstance,
                                            decoder: errorDecoder)
            XCTFail("Should have gotten an exception here")
        }
        catch let error as NoteFileError {
            XCTAssertEqual(error, expectedError)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func test_loadItem_ifFileDoesNotExist_returnsNil() throws {
        let readError = CocoaError(.fileReadNoSuchFile)
        func errorDecoder(url: URL) throws -> NoteContents {
            throw readError
        }
        
        let testObject = NoteFileManager()
        let contents = try testObject.loadItem(id: NoteId.testInstance,
                                           decoder: errorDecoder)
        XCTAssertNil(contents)
    }
    
    func test_loadNoteMetas_readsContentsOfDocumentDirectory() throws {
        var contentsOfDirectory_paramDir: URL?
        func contentsOfDirectoryStub(dir: URL) -> [URL] {
            contentsOfDirectory_paramDir = dir
            
            return []
        }
        
        let testObject = NoteFileManager()
        let _ = try testObject.loadNoteMetas(contentsOfDirectory: contentsOfDirectoryStub,
                                             decoder: { _ in NoteMeta.testInstance})
        
        XCTAssertEqual(contentsOfDirectory_paramDir, NoteFileManager.noteDirectory)
    }
    
    func test_loadNoteMetas_noFilesReturnsNoNotes() throws {
        let testObject = NoteFileManager()

        let returnedNotes = try testObject.loadNoteMetas(contentsOfDirectory: { _ in [] },
                                                         decoder: { _ in NoteMeta.testInstance })

        XCTAssertEqual(returnedNotes.isEmpty, true)
    }

    func test_loadNoteMetas_decodesMetaFiles() throws {
        let noteFile = NoteContents.fileURL(id: NoteId.testInstance)
        let noteMetaFile = NoteMeta.fileURL(id: NoteId.testInstance)
        
        let files = [noteFile, noteMetaFile]
        func contentsOfDirectoryStub(_: URL) -> [URL] { return files }
        
        var decoder_paramURLs = [URL]()
        func decoderStub(url: URL) -> NoteMeta {
            decoder_paramURLs += [url]
            
            return NoteMeta.testInstance
        }

        let testObject = NoteFileManager()

        let _ = try testObject.loadNoteMetas(contentsOfDirectory: contentsOfDirectoryStub,
                                             decoder: decoderStub)

        XCTAssertEqual(decoder_paramURLs, [noteMetaFile])
    }
    
    func test_loadNoteMetas_returnsDecodedFiles() throws {
        let files = (0...3)
            .map { _ in NoteMeta.fileURL(id: NoteId.testInstance) }
        
        func contentsOfDirectoryStub(_: URL) -> [URL] { return files }
        
        var metaForFile = [URL: NoteMeta]()
        
        files.forEach { metaForFile[$0] = NoteMeta.testInstance }
                
        let decoderStub = { metaForFile[$0]! }

        let testObject = NoteFileManager()

        let noteMetas = try testObject.loadNoteMetas(contentsOfDirectory: contentsOfDirectoryStub,
                                                     decoder: decoderStub)

        XCTAssertEqual(Set(noteMetas), Set(metaForFile.values))
    }
    
    func test_loadNoteMetas_convertsExceptionFromContentsOfDirectory() throws {
        let contentsError = CocoaError(.fileReadNoSuchFile)
        func errorContents(_: URL) throws -> [URL] {
            throw contentsError
        }

        let testObject = NoteFileManager()

        do {
            let _ = try testObject.loadNoteMetas(contentsOfDirectory: errorContents,
                                                 decoder: { _ in NoteMeta.testInstance })
            XCTFail("Should have gotten an exception here")
        }
        catch let loadError as NoteFileError {
            let expectedError = NoteFileError.loadFailure(error: contentsError)
            XCTAssertEqual(loadError, expectedError)
        } catch {
            XCTFail("Unexpected error")
        }
    }
    
    func test_loadNoteMetas_convertsExceptionFromDecoder() throws {
        let files = (1...3)
            .map { _ in NoteMeta.fileURL(id: NoteId.testInstance) }
        func errorContents(_: URL) throws -> [URL] {
            return files
        }
        
        let decoderError = URLError(.badServerResponse)

        func errorDecoder(url: URL) throws -> NoteMeta {
            throw decoderError
        }

        let testObject = NoteFileManager()

        do {
            let _ = try testObject.loadNoteMetas(contentsOfDirectory: errorContents,
                                                 decoder: errorDecoder)
            XCTFail("Should have gotten an exception here")
        }
        catch let loadError as NoteFileError {
            let expectedError = NoteFileError.loadFailure(error: decoderError)
            XCTAssertEqual(loadError, expectedError)
        } catch {
            XCTFail("Unexpected error")
        }
    }
        
    func test_saveItem_writesItemToFileURL() throws {
        var encoder_paramContents: NoteContents?
        var encoder_paramURL: URL?
        func encoderStub(contents: NoteContents, url: URL) {
            encoder_paramContents = contents
            encoder_paramURL = url
        }
        
        let testObject = NoteFileManager()
        
        let contents = NoteContents.testInstance
        let expectedURL = NoteContents.fileURL(id: contents.id)
        
        try testObject.saveItem(item: contents, encoder: encoderStub)
        
        XCTAssertEqual(encoder_paramContents, contents)
        XCTAssertEqual(encoder_paramURL, expectedURL)
    }
    
    func test_saveItem_convertsExceptionFromEncoder() throws {
        let writeError = NSError(domain: "", code: 0)
        
        func errorEncoder(note: NoteContents, url: URL) throws {
            throw writeError
        }
        
        let testObject = NoteFileManager()
        
        do {
            try testObject.saveItem(item: NoteContents.testInstance,
                                    encoder: errorEncoder)
            XCTFail("Should have gotten an exception here")
        }
        catch let saveError as NoteFileError {
            let expectedError = NoteFileError.saveFailure(error: writeError)
            XCTAssertEqual(saveError, expectedError)
        } catch {
            XCTFail("Unexpected error")
        }
    }
    
    func test_deleteAllFiles_retrievesListOfFiles() throws {
        var contentsOfDirectory_paramDir: URL?
        func contentsOfDirectoryStub(dir: URL) -> [URL] {
            contentsOfDirectory_paramDir = dir
            
            return []
        }
        
        let testObject = NoteFileManager()
        try testObject.deleteAllFiles(contentsOfDirectory: contentsOfDirectoryStub)
        
        XCTAssertEqual(contentsOfDirectory_paramDir, NoteFileManager.noteDirectory)
    }
    
    func test_deleteAllFiles_removesFiles() throws {
        var removeFileStub_paramURL: URL?
        func removeFileStub(url: URL) {
            removeFileStub_paramURL = url
        }
        
        let url = URL(string: "file.txt")!
        let testObject = NoteFileManager()
        try testObject.deleteAllFiles(contentsOfDirectory: { _ in [url] },
                                              removeFile: removeFileStub)
        
        XCTAssertEqual(removeFileStub_paramURL, url)
    }
    
    func test_deleteAllFiles_removesAllTheFiles() throws {
        var removeFileStub_calledCount = 0
        func removeFileStub(url: URL) {
            removeFileStub_calledCount += 1
        }
        
        let urlCount = 10
        let urls =  (1...10).map { _ in URL(string: "file.txt")! }
        let testObject = NoteFileManager()
        let _ = try testObject.deleteAllFiles(contentsOfDirectory: { _ in urls },
                                              removeFile: removeFileStub)
        
        XCTAssertEqual(removeFileStub_calledCount, urlCount)
    }    
}

extension Array where Element == NoteMeta {
    func sortedById() -> [NoteMeta] {
        self.sorted { meta1, meta2 in
            meta1.id < meta2.id
        }
    }
}
