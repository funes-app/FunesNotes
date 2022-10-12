import Foundation
import Notepad
import SwiftUI

struct TextView: UIViewRepresentable {
    @Binding private var text: String
        
    private let theme: Theme.BuiltIn
    
    init(_ text: Binding<String>,
         colorScheme: ColorScheme) {
        _text = text
        theme = themeForColorScheme(colorScheme)
    }
    
    func makeUIView(context: Context) -> UITextView {
        let notepad = Notepad(frame: .zero, theme: theme)

        notepad.delegate = context.coordinator
        return notepad
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        textView.text = text
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

fileprivate func themeForColorScheme(_ colorScheme: ColorScheme) -> Theme.BuiltIn {
    colorScheme == .dark ?
    Theme.BuiltIn.OneDark :
    Theme.BuiltIn.OneLight
}
