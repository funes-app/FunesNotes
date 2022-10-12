import Foundation
import Combine
import SwiftUI

class NoteListViewModel: ObservableObject {
    @Published var noteMetas = [NoteMeta]()
    
    var showSyncProgress: Bool {
        if case .idle = syncActivity {
            return false
        }
        return true
    }
    
    @Published var syncActivity = SynchronizerActivityStatus.idle
    
    @Published var showEditNoteView = false {
        didSet {
            if !showEditNoteView {
                self.deselectNote()
            }
        }
    }
        
    var noteMetaToDelete: NoteMeta?
    @Published var showDeleteConfirmation = false
    
    @Published var showLogoutConfirmation = false
    
    var navigationTitle: String {
        shipSession.ship?.string ?? "Notes"
    }

    var sigilURL: URL {
        let urlPrefix = "https://api.urbit.live/images/"
        let zodUrlString = urlPrefix + "zod_black.png"

        guard let ship = shipSession.ship else {
            return URL(string: zodUrlString)!
        }

        var urlString = ""
        switch ship.title {
        case .comet:
            urlString = zodUrlString
        case .moon:
            urlString = urlPrefix + "\(ship.parent)_black.png"
        default:
            urlString = urlPrefix + "\(ship)_black.png"
        }
        
        return URL(string: urlString)!
    }
    
    private var selectedNoteId: NoteId? {
        didSet {
            userDefaults.lastSelectedNoteId = selectedNoteId
        }
    }
    
    var editViewModel: NoteEditViewModel {
        noteEditViewModel as? NoteEditViewModel ?? NoteEditViewModel(fileConnector: fileConnector)
    }
    
    private let appViewModel: AppViewModeling
    private let noteEditViewModel: NoteEditViewModeling
    private let fileConnector: FileConnecting
    private let shipSession: ShipSessioning
    private let graphStoreSync: GraphStoreSyncing?
    private let userDefaults: UserDefaults
    
    private var cancellables: Set<AnyCancellable> = []
    
    convenience init(appViewModel: AppViewModeling) {
        let noteEditViewModel = NoteEditViewModel(fileConnector: appViewModel.fileConnector)
        self.init(appViewModel: appViewModel,
                  noteEditViewModel: noteEditViewModel,
                  userDefaults: .standard)
    }

    internal init(appViewModel: AppViewModeling,
                  noteEditViewModel: NoteEditViewModeling,
                  userDefaults: UserDefaults,
                  dispatchQueue: DispatchQueue = DispatchQueue.main) {
        self.appViewModel = appViewModel
        self.fileConnector = appViewModel.fileConnector
        self.shipSession = appViewModel.shipSession
        self.graphStoreSync = appViewModel.graphStoreSync
        
        self.noteEditViewModel = noteEditViewModel
        self.userDefaults = userDefaults
        
        self.fileConnector
            .noteDeleted
            .receive(on: dispatchQueue)
            .sink(receiveValue: { [weak self] in
                self?.handleDeletedNote(id: $0)
            })
            .store(in: &cancellables)
        
        self.fileConnector
            .metadataCreated
            .receive(on: dispatchQueue)
            .sink(receiveValue: { [weak self] in
                self?.updateNoteMetas(updatedNoteMeta: $0)
            })
            .store(in: &cancellables)
        
        self.fileConnector
            .metadataUpdated
            .receive(on: dispatchQueue)
            .sink(receiveValue: { [weak self] in
                self?.updateNoteMetas(updatedNoteMeta: $0)
            })
            .store(in: &cancellables)
        
        self.graphStoreSync?
            .activityChanged
            .receive(on: dispatchQueue)
            .assign(to: &$syncActivity)
        
        self.noteEditViewModel
            .noteContentsChanged
            .sink(receiveValue: { [weak self] in
                self?.handleNoteTextUpdate(note: $0)
            })
            .store(in: &cancellables)
    }
    
    func refresh() async {
        await graphStoreSync?.synchronize()

        await loadNoteMetas()        
    }

    func loadNoteMetas() async {
        let noteMetas = await fileConnector
            .loadNoteMetas()
            .ordered()
            .nondeleted()
        await setNoteMetas(noteMetas)
    }
    
    @MainActor
    private func setNoteMetas(_ noteMetas: [NoteMeta]) {
        self.noteMetas = noteMetas
    }
    
    func loadLastSelectedNote() {
        guard let lastSelectedNoteId = userDefaults.lastSelectedNoteId,
              lastSelectedNoteId != selectedNoteId else {
            return
        }

        selectNote(id: lastSelectedNoteId)
    }
    
    func showDeletionConfirmation(noteMeta: NoteMeta) {
        noteMetaToDelete = noteMeta
        showDeleteConfirmation = true
    }
    
    func delete() {
        guard let id = noteMetaToDelete?.id else { return }
        fileConnector.delete(id: id)
    }
    
    func sigilTapped() {
        showLogoutConfirmation = true
    }
    
    func logout() async {
        await appViewModel.logout()
    }
    
    func createNewNoteTapped() {
        noteEditViewModel.newNoteContents()
        selectedNoteId = noteEditViewModel.noteContentsBeingEdited.id
        showEditNoteView = true
    }
    
    func selectNote(id: NoteId) {
        noteEditViewModel.loadNoteContents(id: id)
        selectedNoteId = id
        showEditNoteView = true
    }
    
    private func deselectNote() {
        selectedNoteId = nil
    }

    private func removeNoteMeta(id: NoteId) {
        noteMetas = noteMetas.filter { $0.id != id }
    }
    
    private func handleDeletedNote(id: NoteId) {
        let nextSelectedNoteId = noteMetas.nextSelectedId(deletedNoteId: id)
        withAnimation {
            removeNoteMeta(id: id)
        }
                
        if id == selectedNoteId {
            if let nextSelectedNoteId = nextSelectedNoteId {
                selectNote(id: nextSelectedNoteId)
            }
            else {
                showEditNoteView = false
                noteEditViewModel.newNoteContents()
            }
        }
    }
    
    private func handleNoteTextUpdate(note: NoteContents) {
        let updatedNoteMeta = NoteMeta(note,
                                       contentsLastModified: Date.now,
                                       metadataLastModified: Date.now)
        updateNoteMetas(updatedNoteMeta: updatedNoteMeta)
        selectedNoteId = note.id
    }
    
    private func updateNoteMetas(updatedNoteMeta: NoteMeta) {
        removeNoteMeta(id: updatedNoteMeta.id)
        
        noteMetas
            .append(updatedNoteMeta)
        
        noteMetas = noteMetas
            .ordered()
    }
}
