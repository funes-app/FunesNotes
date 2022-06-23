import Foundation
import Combine
import SwiftUI

class NoteEditViewModel: ObservableObject, NoteEditViewModeling {
    @Published var noteContentsBeingEdited: NoteContents {
        willSet {
            if noteContentsBeingEdited.id != newValue.id,
               !noteContentsBeingEdited.isEmpty,
               noteContentsBeingEdited.text.isEmpty == true {
                deleteNoteContentsBeingEdited()
            }
        }
    }
    
    var noteContentsChanged: AnyPublisher<NoteContents, Never> {
        $noteContentsBeingEdited
            .scan(nil) { (previousPair, current) -> (NoteContents?, NoteContents) in
                (previousPair?.1, current)
            }
            .compactMap { $0 }
            .filter { pair in
                pair.0?.id == pair.1.id &&
                pair.0?.text != pair.1.text
            }
            .map { $0.1 }
            .eraseToAnyPublisher()
    }
    
    var text: Binding<String> {
        Binding(
            get: { self.noteContentsBeingEdited.text },
            set: { self.noteContentsBeingEdited.text = $0}
        )
    }
    
    @Published var showDeleteConfirmation = false
    
    @Published var isTextEditorFocused: Bool = false
    
    @Published var isSharePresented = false
    
    private var noteBeingDeleted: NoteId?
    
    private var cancellables: Set<AnyCancellable> = []
    
    private var fileConnector: FileConnecting
    private var noteSaver: NoteSaver?
    
    private static let defaultSaverDebounceTime = 2 * 1_000_000_000

    init(fileConnector: FileConnecting,
         noteContentsBeingEdited: NoteContents = .empty,
         saverDebounceTime: Int = defaultSaverDebounceTime) {
        self.fileConnector = fileConnector
        self.noteContentsBeingEdited = noteContentsBeingEdited
        
        noteSaver = NoteSaver(fileConnector: fileConnector,
                              noteContentsChanged: noteContentsChanged,
                              debounceTime: saverDebounceTime)
    }
    
    // 750 ms
    private static let defaultDelayDuration: UInt64 = 750_000_000
    
    @MainActor
    func focusOnTextEditWithDelay(delayDuration: UInt64 = defaultDelayDuration) async {
        do {
            // Delay focusing for a second to ensure the view is really loaded
            // This is apparently a bug on Apple's end
            try await Task.sleep(nanoseconds: delayDuration)
        } catch {
            // sleep() will throw if it's cancelled, but it never will be.
        }
        
        self.isTextEditorFocused = true
    }
    
    func showDeletionConfirmation() {
        showDeleteConfirmation = true
    }
    
    func newNoteContents() {
        noteContentsBeingEdited = NoteContents()
    }
    
    func loadNoteContents(id: NoteId) {
        noteContentsBeingEdited = fileConnector.loadNoteContents(id: id) ?? .empty
    }
    
    func delete() {
        deleteNoteContentsBeingEdited()
    }

    private func deleteNoteContentsBeingEdited() {
        guard noteContentsBeingEdited.id != noteBeingDeleted else { return }
        noteBeingDeleted = noteContentsBeingEdited.id
        fileConnector.delete(id: noteContentsBeingEdited.id)
    }
}
