import XCTest
import UrsusHTTP
import SwiftGraphStore
@testable import FunesNotes

class NoteContentsTests: XCTestCase {
    private let jsonString = """
        {"id":"123456","text":"This is the text."}
        """
    
    func test_fileURL_addsIdAndDotJsonToTheDocumentDir() throws {
        let noteDir = NoteFileManager
            .noteDirectory
            .absoluteString
        let id = NoteId.testInstance
        let expectedDir = "\(noteDir)\(id).json"
        XCTAssertEqual(NoteContents.fileURL(id: id).absoluteString, expectedDir)
    }
        
    func test_empty_hasNoIdOrTest() {
        let testObject = NoteContents.empty
        
        XCTAssertEqual(testObject.id, NoteId(0))
        XCTAssertEqual(testObject.text, "")
    }
    
    func test_isEmpty_whenIdIsEmpty_returnsTrue() {
        let empty = NoteContents(id: NoteId.empty, text: "ignores text")
        XCTAssertEqual(empty.isEmpty, true)
    }
    
    func test_isEmpty_whenIdIsNotEmpty_returnsFalse() {
        let empty = NoteContents(id: NoteId.testInstance, text: "still ignores text")
        XCTAssertEqual(empty.isEmpty, false)
    }
    
    func test_withUpdatedText_keepsIdAndReplacesText() {
        let id = NoteId.testInstance
        let text = UUID().uuidString
        let contents = NoteContents(id: id, text: text)
        
        let updatedText = UUID().uuidString
        let updatedContents = contents.withUpdatedText(updatedText)
        
        XCTAssertEqual(updatedContents.id, id)
        XCTAssertEqual(updatedContents.text, updatedText)
    }

    func test_encode() throws {
        let id = NoteId(123456)
        let contents = NoteContents(id: id, text: "This is the text.")

        let data = try JSONEncoder().encode(contents)
        let dataString = String(data: data, encoding: .utf8)
        
        XCTAssertEqual(dataString, jsonString)
    }

    func test_decode() throws {
        let data = jsonString.data(using: .utf8)!
        let contents = try JSONDecoder().decode(NoteContents.self, from: data)

        let id = NoteId("123456")!
        let expectedContents = NoteContents(id: id, text: "This is the text.")

        XCTAssertEqual(contents, expectedContents)
    }
    
    func test_encodeAndDecode() throws {
        let expectedContents = NoteContents.testInstance
        let jsonEncoder = JSONEncoder()
        let data = try XCTUnwrap(try? jsonEncoder.encode(expectedContents))
        
        let jsonDecoder = JSONDecoder()
        let contents: NoteContents = try XCTUnwrap(try? jsonDecoder.decode(NoteContents.self, from: data))
        XCTAssertEqual(contents, expectedContents)
    }
    
    func test_contents_usesJson() {
        let id = NoteId(123456)
        let testObject = NoteContents(id: id, text: "This is the text.")

        let expectedContents = Content(text: jsonString)
        XCTAssertEqual(testObject.contents, [expectedContents])
    }
    
    func test_idPathComponent_convertsToString() {
        let id = NoteId(1234)
        
        let expectedPathComponent = "1234"
        XCTAssertEqual(NoteContents.idPathComponent(id: id),
                       expectedPathComponent)
    }
}
