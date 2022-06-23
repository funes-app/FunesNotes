import SwiftUI

struct NoteListViewFooter: View {
    let viewModel: NoteListViewModel
    var body: some View {
        HStack {
            if viewModel.showSyncProgress {
                ProgressView()
            }
            
            Spacer()
            IconButton("square.and.pencil"){
                viewModel.createNewNoteTapped()
            }
        }
        .padding(Edge.Set.bottom)
        .padding(Edge.Set.horizontal)
    }
}

struct NoteListViewFooter_Previews: PreviewProvider {
    static var previews: some View {
        NoteListViewFooter(viewModel: NoteListViewModel.makePreviewVM(activityStatus: .downloading))
            .previewLayout(.sizeThatFits)
    }
}
