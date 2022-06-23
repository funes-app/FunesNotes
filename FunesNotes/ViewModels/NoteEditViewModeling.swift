import Combine

protocol NoteEditViewModeling {
    var noteContentsBeingEdited: NoteContents { get }
    var noteContentsChanged: AnyPublisher<NoteContents, Never> { get }
    
    func newNoteContents()
    func loadNoteContents(id: NoteId)
}
