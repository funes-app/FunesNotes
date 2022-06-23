import Foundation
import Combine
@testable import FunesNotes

class FakeNoteEditViewModel: NoteEditViewModeling {
    var noteContentsBeingEdited: NoteContents = NoteContents()
    
    @Published var contentsWithChangedText: NoteContents?
    var noteContentsChanged: AnyPublisher<NoteContents, Never> {
        $contentsWithChangedText
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    var newNoteContents_calledCount = 0
    func newNoteContents() {
        newNoteContents_calledCount += 1
    }
    
    var loadNoteContents_calledCount = 0
    var loadNoteContents_paramId: NoteId?
    func loadNoteContents(id: NoteId) {
        loadNoteContents_calledCount += 1
        loadNoteContents_paramId = id
    }
}
