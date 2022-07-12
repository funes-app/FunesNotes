import SwiftUI

struct NoteEditor: View {
    private var font: UIFont {
        UIFont(name: "AnonymousPro-Regular", size: 18)!
    }

    var text: Binding<String>
    var body: some View {
        let view: TextView = TextView(text)
        
        return view
            .keyboardType(.default)
            .multilineTextAlignment(.leading)
            .padding()
    }
}


struct NoteEditor_Previews: PreviewProvider {
    static var previews: some View {
        let text = """
# Headline

## Subhead
        
Here's a _line_ with some **bolded** stuff

~~This should be struck through~~

- Item 1
- Item 2
- Item 3
"""
        NoteEditor(text: .constant(text))
    }
}
