import SwiftUI

struct NoteEditor: View {
    private var font: Font {
        .custom("AnonymousPro-Regular", fixedSize: 18)
    }

    var text: Binding<String>
    var body: some View {
        TextEditor(text: text)
            .keyboardType(.default)
            .font(font)
            .padding()
    }
}


struct NoteEditor_Previews: PreviewProvider {
    static var previews: some View {
        NoteEditor(text: .constant("This is a note right here"))
    }
}
