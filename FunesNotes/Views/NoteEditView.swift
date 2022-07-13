import SwiftUI

struct NoteEditView: View {
    @ObservedObject private(set) var viewModel: NoteEditViewModel
    
    @FocusState var isTextEditorFocused: Bool
     
    private var textEditorFont: Font {
        .custom("AnonymousPro-Regular", fixedSize: 18)
    }
    
    var body: some View {
        VStack {
            NoteEditor(text: viewModel.text)
                .focused($isTextEditorFocused)
            
            Divider()
            
            NoteEditViewFooter(viewModel: viewModel)
        }
        .alert("Are you sure you want to delete this?",
               isPresented: $viewModel.showDeleteConfirmation,
               actions: {
            Button("Yes", role: .destructive) {
                viewModel.delete()
            }
        })
        .sheet(isPresented: $viewModel.isSharePresented, content: {
            ActivityViewController(activityItems: [viewModel.noteContentsBeingEdited.text])
        })
        .onAppear {
            Task {
                await self.viewModel.focusOnTextEditWithDelay()
            }
        }
        .onChange(of: isTextEditorFocused) { self.viewModel.isTextEditorFocused = $0 }
        .onChange(of: viewModel.isTextEditorFocused) { self.isTextEditorFocused = $0 }
        .navigationBarTitleDisplayMode(.inline)
        .padding(Edge.Set.bottom)
    }    
}

struct NoteEditView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = NoteEditViewModel(fileConnector: FileConnector())
        let text = (1...30)
            .map { i in "Line \(i)"}
            .joined(separator: "\n")
        viewModel.noteContentsBeingEdited = NoteContents(text: text)
        
        return NoteEditView(viewModel: viewModel)
    }
}
