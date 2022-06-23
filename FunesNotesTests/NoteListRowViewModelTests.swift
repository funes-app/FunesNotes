import XCTest
@testable import FunesNotes

class NoteListRowViewModelTests: XCTestCase {
    
    func test_title_usesNoteMetaTitle() {
        let expectedTitle = UUID().uuidString
        let noteMeta = NoteMeta(id: NoteId.testInstance,
                                title: expectedTitle,
                                subtitle: "",
                                contentsLastModified: .now,
                                metadataLastModified: .now,
                                deleted: false)
        let testObject = NoteListRowViewModel()
        let title = testObject.title(noteMeta: noteMeta)
        XCTAssertEqual(title, expectedTitle)
    }
    
    func test_title_whenNil_usesNewNote() {
        let noteMeta = NoteMeta(id: NoteId.testInstance,
                                title: nil,
                                subtitle: nil,
                                contentsLastModified: .now,
                                metadataLastModified: .now,
                                deleted: false)
        let testObject = NoteListRowViewModel()
        let title = testObject.title(noteMeta: noteMeta)
        XCTAssertEqual(title, "New Note")
    }
    
    func test_title_whenEmpty_usesNewNote() {
        let noteMeta = NoteMeta(id: NoteId.testInstance,
                                title: "",
                                subtitle: "",
                                contentsLastModified: .now,
                                metadataLastModified: .now,
                                deleted: false)
        let testObject = NoteListRowViewModel()
        let title = testObject.title(noteMeta: noteMeta)
        XCTAssertEqual(title, "New Note")
    }
    
    func test_subtitle_usesNoteMeta() {
        let expectedSubtitle = UUID().uuidString
        let noteMeta = NoteMeta(id: NoteId.testInstance,
                                title: nil,
                                subtitle: expectedSubtitle,
                                contentsLastModified: .now,
                                metadataLastModified: .now,
                                deleted: false)
        let testObject = NoteListRowViewModel()
        let subtitle = testObject.subtitle(noteMeta: noteMeta)
        XCTAssertEqual(subtitle, expectedSubtitle)
    }
    
    func test_subtitle_whenNil_returnsEmptyString() {
        let noteMeta = NoteMeta(id: NoteId.testInstance,
                                title: nil,
                                subtitle: nil,
                                contentsLastModified: .now,
                                metadataLastModified: .now,
                                deleted: false)
        let testObject = NoteListRowViewModel()
        let subtitle = testObject.subtitle(noteMeta: noteMeta)
        XCTAssertEqual(subtitle, "")
    }

    func test_lastModifiedDescription_whenWithinTheSameDay_showTime() {
        let noon = try! Date("1/1/11 12:00 PM", strategy: .dateTime)
        let hourThirty = DateComponents(hour: 1, minute: 30)
        let oneThirty = Calendar.current.date(byAdding: hourThirty, to: noon)!
        
        let noteMeta = NoteMeta.withContentsLastModified(oneThirty)
        
        let description = NoteListRowViewModel().lastModifiedDescription(noteMeta: noteMeta, now: noon)
        XCTAssertEqual(description, "1:30 PM")
    }
    
    func test_lastModifiedDescription_whenOutsideTheSameDay_showDate() {
        let augustTen = try! Date("8/10/11 12:00 PM", strategy: .dateTime)
        let twoDaysAgo = DateComponents(day: -2)
        let augustEight = Calendar.current.date(byAdding: twoDaysAgo, to: augustTen)!
        
        let noteMeta = NoteMeta.withContentsLastModified(augustEight)
        
        let description = NoteListRowViewModel().lastModifiedDescription(noteMeta: noteMeta, now: augustTen)
        XCTAssertEqual(description, "8/8/11")
    }
}

private extension NoteMeta {
    static func withContentsLastModified(_ contentsLastModified: Date) -> NoteMeta {
        NoteMeta(id: NoteId.testInstance,
                 title: nil,
                 subtitle: nil,
                 contentsLastModified: contentsLastModified,
                 metadataLastModified: .now,
                 deleted: false)
    }
}

