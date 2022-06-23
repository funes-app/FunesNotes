import XCTest
import UrsusHTTP
import SwiftGraphStore

@testable import FunesNotes

class NoteMetaTests: XCTestCase {
    func test_decodesV0Json() throws {
        let metadata: NoteMeta = try JSONLoader.load("metadata-v0.json")
        
        let expectedModified = Date(timeIntervalSinceReferenceDate:  675687433.538625)
        let expectedMetadata = NoteMeta(id: NoteId("675687417"),
                                        title: "This is the title",
                                        subtitle: "This is the subtitle",
                                        contentsLastModified: expectedModified,
                                        metadataLastModified: expectedModified,
                                        deleted: false)
        
        XCTAssertEqual(metadata, expectedMetadata)
    }
    
    func test_decodesV1Json() throws {
        let metadata: NoteMeta = try JSONLoader.load("metadata-v1.json")
        
        let expectedMetadata = NoteMeta(id: NoteId("3118630897"),
                                        title: "TITLE",
                                        subtitle: "SUBTITLE",
                                        contentsLastModified: Date(timeIntervalSince1970: 0),
                                        metadataLastModified: Date(timeIntervalSinceReferenceDate: 0),
                                        deleted: true)
        
        XCTAssertEqual(metadata, expectedMetadata)
    }
    
    func test_decodesNoTitleJson() throws {
        let metadata: NoteMeta = try JSONLoader.load("metadata-noTitle.json")
        
        let expectedMetadata = NoteMeta(id: NoteId("3118630897"),
                                        title: nil,
                                        subtitle: nil,
                                        contentsLastModified: Date(timeIntervalSince1970: 0),
                                        metadataLastModified: Date(timeIntervalSinceReferenceDate: 0),
                                        deleted: true)
        
        XCTAssertEqual(metadata, expectedMetadata)
    }
    
    func test_init_fromNote_title_usesFirstLine() {
        let expectedTitle = randomString()
        
        let contents = NoteContents(text: expectedTitle)
        
        let noteMeta = NoteMeta(contents,
                                contentsLastModified: Date.now,
                                metadataLastModified: Date.now)
        
        XCTAssertEqual(noteMeta.title, expectedTitle)
    }
    
    func test_init_fromNote_title_ignoresEmptyLinesAndWhitespace() {
        let expectedTitle = randomString()
        let text = "\n\n\t  \n    \n\(expectedTitle)"
        
        let contents = NoteContents(text: text)
        
        let noteMeta = NoteMeta(contents,
                                contentsLastModified: Date.now,
                                metadataLastModified: Date.now)
        
        XCTAssertEqual(noteMeta.title, expectedTitle)
    }
    
    func test_init_fromNote_title_ignoresSubsequentLines() {
        let expectedTitle = randomString()
        let text = "\(expectedTitle)\n\(randomString())\n\(randomString())"
        
        let contents = NoteContents(text: text)
        
        let noteMeta = NoteMeta(contents,
                                contentsLastModified: Date.now,
                                metadataLastModified: Date.now)
        
        XCTAssertEqual(noteMeta.title, expectedTitle)
    }

    func test_init_fromNote_title_whenEmptyString_titleIsNil() {
        let contents = NoteContents(text: "")
        
        let noteMeta = NoteMeta(contents,
                                contentsLastModified: Date.now,
                                metadataLastModified: Date.now)

        XCTAssertNil(noteMeta.title)
    }
    
    func test_init_fromNote_subtitle_usesSecondLine() {
        let expectedSubtitle = randomString()
        let text = "\(randomString())\n\(expectedSubtitle)"
        
        let contents = NoteContents(text: text)
        
        let noteMeta = NoteMeta(contents,
                                contentsLastModified: Date.now,
                                metadataLastModified: Date.now)
        
        XCTAssertEqual(noteMeta.subtitle, expectedSubtitle)
    }
    
    func test_init_fromNote_subtitle_ignoresEmptyLinesAndWhitespace() {
        let expectedSubtitle = randomString()
        let text = "\(randomString())\n\n  \n\t\n\(expectedSubtitle)\n\(randomString())"
        
        let contents = NoteContents(text: text)
        
        let noteMeta = NoteMeta(contents,
                                contentsLastModified: Date.now,
                                metadataLastModified: Date.now)

        XCTAssertEqual(noteMeta.subtitle, expectedSubtitle)
    }
    
    func test_init_fromNote_subtitle_ignoresSubsequentLines() {
        let expectedSubtitle = randomString()
        let text = "\(randomString())\n\(expectedSubtitle)\n\(randomString())"
        
        let contents = NoteContents(text: text)
        let noteMeta = NoteMeta(contents,
                                contentsLastModified: Date.now,
                                metadataLastModified: Date.now)
        
        XCTAssertEqual(noteMeta.subtitle, expectedSubtitle)
    }

    func test_init_fromNote_subtitle_whenEmptyString_subtitleIsEmpty() {
        let contents = NoteContents(text: "")
        let noteMeta = NoteMeta(contents,
                                contentsLastModified: Date.now,
                                metadataLastModified: Date.now)
        
        XCTAssertNil(noteMeta.subtitle)
    }
    
    func test_init_fromNote_subtitle_whenTextHasOneLine_subtitleIsEmpty() {
        let contents = NoteContents(text: "just one line\n")
        let noteMeta = NoteMeta(contents,
                                contentsLastModified: Date.now,
                                metadataLastModified: Date.now)
        
        XCTAssertNil(noteMeta.subtitle)
    }
    
    func test_init_fromNote_lastModified_usesParameter() {
        let contents = NoteContents(text: "just one line\n")
        let lastModified = Date.distantFuture
        let noteMeta = NoteMeta(contents,
                                contentsLastModified: lastModified,
                                metadataLastModified: Date.now)
        
        XCTAssertEqual(noteMeta.contentsLastModified, lastModified)
    }
    
    func test_init_fromNote_deleted_defaultsToFalse() {
        let contents = NoteContents(text: "just one line\n")
        let noteMeta = NoteMeta(contents,
                                contentsLastModified: Date.now,
                                metadataLastModified: Date.now)
        
        let timeInterval = noteMeta.contentsLastModified.timeIntervalSince(Date.now)
        XCTAssertEqual(timeInterval, 0, accuracy: 0.01)
    }
    
    func test_withDeleted_marksDeleted() {
        let noteMeta = NoteMeta(NoteContents.testInstance,
                                contentsLastModified: Date.now,
                                metadataLastModified: Date(timeIntervalSinceReferenceDate: Double.random(in: 0...1000)),
                                deleted: Bool.random())
        let newDeleted = Bool.random()
        let deletedNoteMeta = noteMeta.withDeleted(newDeleted)
        XCTAssertEqual(deletedNoteMeta.id, noteMeta.id)
        XCTAssertEqual(deletedNoteMeta.title, noteMeta.title)
        XCTAssertEqual(deletedNoteMeta.subtitle, noteMeta.subtitle)
        XCTAssertEqual(deletedNoteMeta.contentsLastModified,
                       noteMeta.contentsLastModified)
        XCTAssertEqual(deletedNoteMeta.metadataLastModified,
                       noteMeta.metadataLastModified)
        XCTAssertEqual(deletedNoteMeta.deleted, newDeleted)
    }
    
    func test_withMetadataLastModified_updatesOnlyMetadataLastModified() {
        let noteMeta = NoteMeta(NoteContents.testInstance,
                                contentsLastModified: Date(timeIntervalSinceReferenceDate: TimeInterval.random(in: 0...1000)),
                                metadataLastModified: Date(timeIntervalSinceReferenceDate: Double.random(in: 0...1000)),
                                deleted: Bool.random())
        let newModified = Date(timeIntervalSinceReferenceDate: Double.random(in: 0...1000))
        let updatedMetadata = noteMeta.withMetadataLastModified(newModified)
        XCTAssertEqual(updatedMetadata.id, noteMeta.id)
        XCTAssertEqual(updatedMetadata.title, noteMeta.title)
        XCTAssertEqual(updatedMetadata.subtitle, noteMeta.subtitle)
        XCTAssertEqual(updatedMetadata.contentsLastModified,
                       noteMeta.contentsLastModified)
        XCTAssertEqual(updatedMetadata.metadataLastModified,
                       newModified)
        XCTAssertEqual(updatedMetadata.deleted, noteMeta.deleted)
    }
    
    func test_fileURL_addsIdAndDotJsonToTheDocumentDir() throws {
        let noteDir = NoteFileManager.noteDirectory.absoluteString
        let id = NoteId.testInstance
        let expectedFile = "\(noteDir)\(id)_meta.json"
        XCTAssertEqual(NoteMeta.fileURL(id: id).absoluteString, expectedFile)
    }
    
    func test_isNoteMetaFile_returnsTrueForFiles() {
        let noteIds = (0...3).map { _ in NoteId.testInstance }
        let metaIds = (0...3).map { _ in NoteId.testInstance }
        
        let noteFiles = noteIds.map { NoteContents.fileURL(id: $0) }
        let metaFiles = metaIds.map { NoteMeta.fileURL(id: $0) }
        let otherFiles = ["42_meta.txt", "17_meta.xml"]
            .map { URL(fileURLWithPath: $0) }
        
        let files = noteFiles + metaFiles + otherFiles
        
        let justMetadataFiles = files.filter { NoteMeta.isNoteMetaFile($0) }
        
        XCTAssertEqual(justMetadataFiles, metaFiles)
    }
    
    func test_lessThan_comparesFileModified() throws {
        var firstMeta = NoteMeta.testInstance
        firstMeta.contentsLastModified = Date.distantFuture
        
        var secondMeta = NoteMeta.testInstance
        secondMeta.contentsLastModified = Date.distantPast
        
        XCTAssertFalse(firstMeta < secondMeta)
    }
    
    func test_contents_dropsTitleAndSubtitle() {
        let lastModified = Date.now
        let deleted = Bool.random()
        
        let testObject = NoteMeta(NoteContents.testInstance,
                                  contentsLastModified: lastModified,
                                  metadataLastModified: lastModified,
                                  deleted: deleted)
        
        
        let metadataForJson = NoteMeta(id: testObject.id,
                                       title: nil,
                                       subtitle: nil,
                                       contentsLastModified: testObject.contentsLastModified,
                                       metadataLastModified: testObject.metadataLastModified,
                                       deleted: testObject.deleted)
        let jsonData = try! JSONEncoder().encode(metadataForJson)
        let expectedJson = String(data: jsonData, encoding: .utf8)!
        let expectedContents = [Content(text: expectedJson)]
        
        XCTAssertEqual(testObject.contents, expectedContents)
    }

    func test_idPathComponent_addsMetaSuffix() {
        let id = NoteId(1234)
        
        let expectedPathComponent = "1234_meta"
        XCTAssertEqual(NoteMeta.idPathComponent(id: id),
                       expectedPathComponent)
    }
    
    private func randomString() -> String{
        (0...10)
            .map { _ in String(Int.random(in: 0...1_000_000_000)) }
            .joined(separator: " ")
    }
}
