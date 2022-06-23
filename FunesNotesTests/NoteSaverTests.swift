import XCTest
import Combine
@testable import FunesNotes

class NoteSaverTests: XCTestCase {
    
    func test_noteBeingEditedPublished_callsSaveWithUpdatedNoteAndMetadata_withDelay() async throws {
        let fileConnector = FakeFileConnector()

        let noteContentsChangedSubject: PassthroughSubject<NoteContents, Never> = PassthroughSubject()
        let publisher = noteContentsChangedSubject
            .eraseToAnyPublisher()
        
        let debounceTime: Int = 500_000

        let dispatchQueue = DispatchQueue(label: "NoteSaver test")
        let testObject = NoteSaver(fileConnector: fileConnector,
                                   noteContentsChanged: publisher,
                                   debounceTime: debounceTime,
                                   dispatchQueue: dispatchQueue)
        XCTAssertNotNil(testObject)
        
        let contents = NoteContents.testInstance
        let noteMeta = NoteMeta(contents)

        noteContentsChangedSubject.send(contents)

        XCTAssertEqual(fileConnector.save_calledCount, 0)
        
        let sleepTime = UInt64(debounceTime*2)
        try? await Task.sleep(nanoseconds: sleepTime)
        
        dispatchQueue.sync {}
        
        XCTAssertEqual(fileConnector.save_calledCount, 1)
        XCTAssertEqual(fileConnector.save_paramContents, contents)

        let paramNoteMeta = try XCTUnwrap(fileConnector.save_paramNoteMeta)
        XCTAssert(paramNoteMeta.equalWithinTimeframe(noteMeta))
    }
}
