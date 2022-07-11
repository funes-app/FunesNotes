import SwiftUI
import TextView

struct NoteEditor: View {
    private var font: UIFont {
        UIFont(name: "AnonymousPro-Regular", size: 18)!
    }

    var text: Binding<String>
    var body: some View {
        let view: TextView = TextView(text)
            .font(font)
        
        return view
            .keyboardType(.default)
            .multilineTextAlignment(.leading)
            .padding()
    }
}


struct NoteEditor_Previews: PreviewProvider {
    static var previews: some View {
        let text = """
        Here's one line
        Here's another line
        """
        NoteEditor(text: .constant(text))
    }
}
