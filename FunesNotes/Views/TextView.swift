import Foundation
import Notepad
import SwiftUI

struct TextView: UIViewRepresentable {
    @Binding private var text: String
    
    let notepad: Notepad
    
    init(_ text: Binding<String>,
         theme: Theme.BuiltIn = Theme.BuiltIn.OneDark) {
        _text = text
        
        notepad = Notepad(frame: .zero, theme: theme)
    }
    
    func makeUIView(context: Context) -> UITextView {
        
        notepad.delegate = context.coordinator
        return notepad
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        notepad.text = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }
}

extension TextView {
    class Coordinator: NSObject, UITextViewDelegate {
        @Binding private var text: String
        
        init(text: Binding<String>) {
            _text = text
        }
        
        func textViewDidChange(_ textView: UITextView) {
            text = textView.text
        }
    }
}
