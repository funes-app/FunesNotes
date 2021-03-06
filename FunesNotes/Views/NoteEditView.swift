import SwiftUI

struct NoteEditView: View {
    @ObservedObject private(set) var viewModel: NoteEditViewModel
    
    @FocusState var isTextEditorFocused: Bool
     
    private var textEditorFont: Font {
        .custom("AnonymousPro-Regular", fixedSize: 18)
    }
    
    var body: some View {
        VStack {
            TextEditor(text: viewModel.text)
                .keyboardType(.default)
                .font(textEditorFont)
                .padding()
                .focused($isTextEditorFocused)
                .onAppear {
                    Task {
                        await self.viewModel.focusOnTextEditWithDelay()
                    }
                }
            
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
        .onChange(of: isTextEditorFocused) { self.viewModel.isTextEditorFocused = $0 }
        .onChange(of: viewModel.isTextEditorFocused) { self.isTextEditorFocused = $0 }
        .navigationBarTitleDisplayMode(.inline)
        .padding(Edge.Set.bottom)
    }    
}

struct NoteEditView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = NoteEditViewModel(fileConnector: FileConnector())
        viewModel.noteContentsBeingEdited = NoteContents(text: "This is some text")
        
        return NoteEditView(viewModel: viewModel)
    }
}
