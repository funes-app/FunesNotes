import XCTest
@testable import FunesNotes

class UserDefaultsValuesTests: XCTestCase {

    private var userDefaults: UserDefaults!
    
    override func setUpWithError() throws {
        userDefaults = UserDefaults(suiteName: #file)
        userDefaults.removePersistentDomain(forName: #file)
    }

    func test_lastSelectedNoteId_defaultsToNil() {
        XCTAssertNil(userDefaults.lastSelectedNoteId)
    }
    
    func test_lastSelectedNoteId_readsFromCorrectKey() {
        let expectedLastSelectedNoteId = NoteId.testInstance
        userDefaults.set(expectedLastSelectedNoteId.description,
                         forKey: "lastSelectedNoteId")
        XCTAssertEqual(userDefaults.lastSelectedNoteId,
                       expectedLastSelectedNoteId)
    }
    
    func test_lastSelectedNoteId_whenUnparsable_returnsNil() {
        userDefaults.set("This is not going to parse",
                         forKey: "lastSelectedNoteId")
        XCTAssertNil(userDefaults.lastSelectedNoteId)
    }
    
    func test_lastSelectedNoteId_writesToCorrectKey() {
        let expectedLastSelectedNoteId = NoteId.testInstance
        userDefaults.lastSelectedNoteId = expectedLastSelectedNoteId
        XCTAssertEqual(userDefaults.string(forKey: "lastSelectedNoteId"),
                       expectedLastSelectedNoteId.description)
    }
    
    func test_lastSelectedNoteId_correctlySetsToNil() {
        userDefaults.lastSelectedNoteId = NoteId.testInstance
        userDefaults.lastSelectedNoteId = nil
        XCTAssertNil(userDefaults.lastSelectedNoteId)
    }
}
