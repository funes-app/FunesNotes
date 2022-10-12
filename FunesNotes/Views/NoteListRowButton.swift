import SwiftUI

struct NoteListRowButton: View {
    let noteMeta: NoteMeta
    let listViewModel: NoteListViewModel
    
    var body: some View {
        Button(action: {
            listViewModel.selectNote(id: noteMeta.id)
        }) {
            NoteListRow(noteMeta: noteMeta)
        }
        .buttonStyle(.borderless)
        .foregroundColor(.primary)
        .swipeActions(allowsFullSwipe: false) {
            IconButton("trash", role: .destructive) {
                listViewModel.showDeletionConfirmation(noteMeta: noteMeta)
            }
        }
    }
}

struct NoteListRowButton_Previews: PreviewProvider {
    static var noteMeta: NoteMeta {
        NoteMeta(NoteContents(text: "Where you come from is gone.\nWhere you thought you were going to weren't never there"),
                 contentsLastModified: Date.now,
                 metadataLastModified: Date.now)
    }

    static var previews: some View {
        return NoteListRowButton(noteMeta: noteMeta,
                                 listViewModel: NoteListViewModel.makePreviewVM())
    }
}
