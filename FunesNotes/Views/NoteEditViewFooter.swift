import SwiftUI

struct NoteEditViewFooter: View {
    let viewModel: NoteEditViewModel
    
    var body: some View {
        HStack {
            IconButton("square.and.arrow.up") {
                viewModel.isSharePresented = true
            }
            Spacer()
            IconButton("trash") {
                viewModel.showDeletionConfirmation()
            }
        }
        .padding(Edge.Set.bottom)
        .padding(Edge.Set.horizontal)
    }
}

struct NoteEditViewFooter_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = NoteEditViewModel(fileConnector: FileConnector())
        viewModel.noteContentsBeingEdited = NoteContents(text: "This is some text")
        
        return NoteEditViewFooter(viewModel: viewModel)
            .previewLayout(.sizeThatFits)
    }
}
