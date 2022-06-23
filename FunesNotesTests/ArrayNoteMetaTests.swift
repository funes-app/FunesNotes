import XCTest
@testable import FunesNotes

class ArrayNoteMetaTests: XCTestCase {
    func test_nextSelectedNoteId_returnsNoteAfterDeleted() {
        let testObject = [ NoteMeta.testInstance,
                           NoteMeta.testInstance,
                           NoteMeta.testInstance,
                           NoteMeta.testInstance ]
        
        let deletedNoteId = testObject[0].id
        let nextSelectedNoteId = testObject.nextSelectedId(deletedNoteId: deletedNoteId)
        
        XCTAssertEqual(nextSelectedNoteId, testObject[1].id)
    }
    
    func test_nextSelectedNoteId_whenDeletedIsLast_returnsSecondToLast() {
        let testObject = [ NoteMeta.testInstance,
                           NoteMeta.testInstance,
                           NoteMeta.testInstance,
                           NoteMeta.testInstance ]

        let deletedNoteId = testObject[3].id
        let nextSelectedNoteId = testObject.nextSelectedId(deletedNoteId: deletedNoteId)
        
        XCTAssertEqual(nextSelectedNoteId, testObject[2].id)
    }
    
    func test_nextSelectedNoteId_whenLastNoteDeleted_returnsNil()  {
        let testObject = [ NoteMeta.testInstance ]
        
        let deletedNoteId = testObject[0].id
        let nextSelectedNoteId = testObject.nextSelectedId(deletedNoteId:  deletedNoteId)
        
        XCTAssertNil(nextSelectedNoteId)
    }
    
    func test_nextSelectedNoteId_whenDeletedIsNotFound_returnsNil() {
        let testObject = [ NoteMeta.testInstance,
                           NoteMeta.testInstance,
                           NoteMeta.testInstance,
                           NoteMeta.testInstance ]
        
        let deletedNoteId = NoteMeta.testInstance.id
        let nextSelectedNoteId = testObject.nextSelectedId(deletedNoteId: deletedNoteId)
        
        XCTAssertNil(nextSelectedNoteId)
    }
    
    func test_ordered_sortsAndReverses() async {
        let noteMetas = (0...5).map { _ in
            NoteMeta.testInstance
        }
            .shuffled()
        
        XCTAssertEqual(noteMetas.ordered(),
                       noteMetas.sorted().reversed())
    }

    func test_nondeleted_onlyReturnsNonDeleted() async {
        let deleted = [
            NoteMeta.testInstance.withDeleted(true),
            NoteMeta.testInstance.withDeleted(true),
            NoteMeta.testInstance.withDeleted(true)
        ]
        let nonDeleted = [
            NoteMeta.testInstance.withDeleted(false),
            NoteMeta.testInstance.withDeleted(false),
            NoteMeta.testInstance.withDeleted(false)
        ]
        let noteMetas = deleted + nonDeleted
        
        XCTAssertEqual(noteMetas.nondeleted(), nonDeleted)
    }
}
