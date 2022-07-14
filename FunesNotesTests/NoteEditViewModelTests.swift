import XCTest
@testable import FunesNotes

class NoteEditViewModelTests: XCTestCase {
    func test_doesNotRetain() {
        var testObject: NoteEditViewModel? = NoteEditViewModel(fileConnector: FakeFileConnector())
        
        weak var weakTestObject = testObject
        testObject = nil
        XCTAssertNil(weakTestObject)
    }
    
    func test_noteTextChangedPublisher_noInitialValue() async throws {
        let testObject = NoteEditViewModel(fileConnector: FakeFileConnector())
        
        let publisher = testObject
            .noteContentsChanged
            .eraseToAnyPublisher()

        try await waitForNoResult(publisher)

        try await waitForNoResult(publisher) {
            testObject.noteContentsBeingEdited = NoteContents.testInstance
        }
    }
    
    func test_noteTextChangedPublisher_publishesNoteWithChangedText() async throws {
        let testObject = NoteEditViewModel(fileConnector: FakeFileConnector())
        
        let previousContents = NoteContents.testInstance
        let expectedContents = previousContents.withUpdatedText()
        
        let publisher = testObject
            .noteContentsChanged
            .eraseToAnyPublisher()
        
        let updatedContents = try await waitForResult(publisher) {
            testObject.noteContentsBeingEdited = previousContents
            testObject.noteContentsBeingEdited = expectedContents
        }
        
        XCTAssertEqual(updatedContents, expectedContents)
    }


    func test_noteTextChangedPublisher_whenNoteChangedHasDifferentID_doesNotPublish() async throws {
        let testObject = NoteEditViewModel(fileConnector: FakeFileConnector())
        
        let previousContents = NoteContents.testInstance
        let expectedContents = NoteContents.testInstance
        
        let publisher = testObject
            .noteContentsChanged
            .eraseToAnyPublisher()
        
        try await waitForNoResult(publisher) {
            testObject.noteContentsBeingEdited = previousContents
            testObject.noteContentsBeingEdited = expectedContents
        }
    }
    
    func test_noteTextChangedPublisher_whenNoteChangedHasSameText_doesNotPublish() async throws {
        let testObject = NoteEditViewModel(fileConnector: FakeFileConnector())
        
        let previousContents = NoteContents.testInstance
        
        let publisher = testObject
            .noteContentsChanged
            .eraseToAnyPublisher()

        try await waitForNoResult(publisher) {
            testObject.noteContentsBeingEdited = previousContents
            testObject.noteContentsBeingEdited = previousContents
        }
    }
        
    func test_text_isBoundToNoteBeingEdited() {
        let testObject = NoteEditViewModel(fileConnector: FakeFileConnector())
        
        let contents = NoteContents.testInstance
        testObject.noteContentsBeingEdited = contents
        
        XCTAssertEqual(testObject.text.wrappedValue, contents.text)
        
        let newText = UUID().uuidString
        testObject.text.wrappedValue = newText
        
        XCTAssertEqual(testObject.noteContentsBeingEdited.text, newText)
    }
    
    func test_noteBeingEdited_willSet_whenPreviousTextIsEmpty_deletes() {
        let fileConnector = FakeFileConnector()

        let contents = NoteContents.testInstance.withUpdatedText("")
        let testObject = NoteEditViewModel(fileConnector: fileConnector,
                                           noteContentsBeingEdited: contents)

        testObject.noteContentsBeingEdited = NoteContents.testInstance
        
        XCTAssertEqual(fileConnector.delete_calledCount, 1)
    }

    func test_noteBeingEdited_willSet_whenPreviousTextIsEmpty_andIdIsSame_doesNotDelete() throws {
        let fileConnector = FakeFileConnector()

        let contents = NoteContents.testInstance.withUpdatedText("")
        let testObject = NoteEditViewModel(fileConnector: fileConnector,
                                           noteContentsBeingEdited: contents)

        let updatedContents = contents.withUpdatedText("now has text")
        testObject.noteContentsBeingEdited = updatedContents
        
        XCTAssertEqual(fileConnector.delete_calledCount, 0)
    }
    
    func test_noteBeingEdited_willSet_whenPreviousContentsHasText_doesNotDelete() throws {
        let fileConnector = FakeFileConnector()

        let contents = NoteContents(text: "This has text")
        let testObject = NoteEditViewModel(fileConnector: fileConnector,
                                           noteContentsBeingEdited: contents)

        testObject.noteContentsBeingEdited = NoteContents.testInstance
        
        XCTAssertEqual(fileConnector.delete_calledCount, 0)
    }
    
    func test_noteBeingEdited_willSet_whenPreviousContentsIsEmpty_doesNotDelete() throws {
        let fileConnector = FakeFileConnector()

        let testObject = NoteEditViewModel(fileConnector: fileConnector,
                                           noteContentsBeingEdited: .empty)
        let contents = NoteContents.testInstance
        testObject.noteContentsBeingEdited = contents

        let updatedContents = contents.withUpdatedText("now has text")
        testObject.noteContentsBeingEdited = updatedContents
        
        XCTAssertEqual(fileConnector.delete_calledCount, 0)
    }
    
    func test_init_wiresUpNoteSaver() async throws {
        let fileConnector = FakeFileConnector()
        let contents = NoteContents.testInstance
        let debounceTime = 5_000_000
        let testObject = NoteEditViewModel(fileConnector: fileConnector,
                                           noteContentsBeingEdited: contents,
                                           saverDebounceTime: debounceTime)
        
        let updatedContents = contents.withUpdatedText()
        testObject.noteContentsBeingEdited = updatedContents
        
        XCTAssertEqual(fileConnector.save_calledCount, 0)
        
        try await Task.sleep(nanoseconds: UInt64(debounceTime*5))
        
        XCTAssertEqual(fileConnector.save_calledCount, 1)
        XCTAssertEqual(fileConnector.save_paramContents, updatedContents)
    }
    
    func test_focusOnTextEditWithDelay_setsFlagAfterDelay() async {
        let testObject = NoteEditViewModel(fileConnector: FakeFileConnector())

        testObject.isTextEditorFocused = false
        await testObject.focusOnTextEditWithDelay(delayDuration: 10)
        XCTAssertEqual(testObject.isTextEditorFocused, true)
    }
    
    func test_newNoteContents_createsNewNoteContents() {
        let testObject = NoteEditViewModel(fileConnector: FakeFileConnector())

        let contents = NoteContents.testInstance
        testObject.noteContentsBeingEdited = contents
        
        testObject.newNoteContents()
        
        XCTAssertNotEqual(testObject.noteContentsBeingEdited.id, contents.id)
        XCTAssertNotEqual(testObject.noteContentsBeingEdited.text, contents.text)
    }
    
    func test_newNoteContents_ifPreviousContentsIsEmpty_deletesIt() {
        let fileConnector = FakeFileConnector()
        let testObject = NoteEditViewModel(fileConnector: fileConnector)

        let contents = NoteContents.testInstance.withUpdatedText("")
        testObject.noteContentsBeingEdited = contents
        
        testObject.newNoteContents()

        XCTAssertEqual(fileConnector.delete_calledCount, 1)
        XCTAssertEqual(fileConnector.delete_paramId, contents.id)
    }
    
    func test_newNoteContents_ifPreviousContentsIsNotEmpty_doesNotDeleteIt() {
        let fileConnector = FakeFileConnector()
        let testObject = NoteEditViewModel(fileConnector: fileConnector)

        let contents = NoteContents.testInstance.withUpdatedText("Has text")
        testObject.noteContentsBeingEdited = contents
        
        testObject.newNoteContents()

        XCTAssertEqual(fileConnector.delete_calledCount, 0)
    }
    
    func test_loadNoteContents_loadsNoteFromFile() {
        let fileConnector = FakeFileConnector()
        
        let contents = NoteContents.testInstance
        fileConnector.loadNoteContents_returnContents = contents
        
        let testObject = NoteEditViewModel(fileConnector: fileConnector)
        
        let id = contents.id
        testObject.loadNoteContents(id: id)
        
        XCTAssertEqual(fileConnector.loadNoteContents_calledCount, 1)
        XCTAssertEqual(fileConnector.loadNoteContents_paramId, id)
        XCTAssertEqual(testObject.noteContentsBeingEdited, contents)
    }
    
    func test_loadNoteContents_whenLoadReturnsNil_setsNoteBeingEditedToEmpty() {
        let fileConnector = FakeFileConnector()
        
        fileConnector.loadNoteContents_returnContents = nil
        
        let testObject = NoteEditViewModel(fileConnector: fileConnector)
        
        testObject.loadNoteContents(id: NoteId.testInstance)
        
        XCTAssert(testObject.noteContentsBeingEdited.isEmpty)
    }
    
    func test_loadNoteContents_ifPreviousNoteIsEmpty_deletesIt() {
        let fileConnector = FakeFileConnector()
        let testObject = NoteEditViewModel(fileConnector: fileConnector)

        let contents = NoteContents.testInstance.withUpdatedText("")
        testObject.noteContentsBeingEdited = contents
        
        let newNoteId = NoteId.testInstance
        testObject.loadNoteContents(id: newNoteId)

        XCTAssertEqual(fileConnector.delete_calledCount, 1)
        XCTAssertEqual(fileConnector.delete_paramId, contents.id)
    }
    
    func test_loadNoteContents_ifPreviousNoteIsNotEmpty_doesNotDeleteIt() {
        let fileConnector = FakeFileConnector()
        let testObject = NoteEditViewModel(fileConnector: fileConnector)

        let contents = NoteContents.testInstance.withUpdatedText("Has text")
        testObject.noteContentsBeingEdited = contents
        
        let newNoteId = NoteId.testInstance
        testObject.loadNoteContents(id: newNoteId)
        
        XCTAssertEqual(fileConnector.delete_calledCount, 0)
    }
    
    func test_loadNoteContents_removesLineFeedsFromContents() {
        let fileConnector = FakeFileConnector()
        let testObject = NoteEditViewModel(fileConnector: fileConnector)
        
        let text = "Text\rwith\rline\rfeeds"
        let contents = NoteContents.testInstance.withUpdatedText(text)
        fileConnector.loadNoteContents_returnContents = contents

        testObject.loadNoteContents(id: NoteId.testInstance)

        let expectedText = "Textwithlinefeeds"
        XCTAssertEqual(testObject.noteContentsBeingEdited.text, expectedText)
    }
    
    func test_delete_deletesNoteContentsBeingEdited() {
        let fileConnector = FakeFileConnector()
        
        let testObject = NoteEditViewModel(fileConnector: fileConnector)
        let contents = NoteContents.testInstance
        testObject.noteContentsBeingEdited = contents
        
        testObject.delete()
        
        XCTAssertEqual(fileConnector.delete_calledCount, 1)
        XCTAssertEqual(fileConnector.delete_paramId, contents.id)
    }
}
