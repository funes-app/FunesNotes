import SwiftUI
import Notepad

struct NoteEditor: View {
    @Environment(\.colorScheme) private var colorScheme
    
    private var font: UIFont {
        UIFont(name: "AnonymousPro-Regular", size: 18)!
    }
    
    var text: Binding<String>
    
    init(_ text: Binding<String>) {
        self.text = text
    }
    
    var body: some View {
        TextView(text, colorScheme: colorScheme)
            .keyboardType(.default)
            .multilineTextAlignment(.leading)
            .padding()
            .id(self.colorScheme)
    }
}


struct NoteEditor_Previews: PreviewProvider {
    static var previews: some View {
        let text = """
# Headline

## Subhead

This is a regular paragraph with some text in it.  In this sentence, I got really excited and wanted everyone to know about _this thing right here_.

But **this thing** was even more important.
 
This reminds me of the time I was talking to my uncle.  He said something like,

> That one thing my uncle said

If I want a small code block, it looks like `this`.

```
A big code block looks like this
```

[Hyperlinks look like this](http://funes.app)

- Here's an item
- Here's another item
"""
        Group {
            NoteEditor(.constant(text))
                .environment(\.colorScheme, .dark)
            NoteEditor(.constant(text))
                .environment(\.colorScheme, .light)
        }
    }
}
