import Foundation
import SwiftUI

struct TextView: UIViewRepresentable {
    @Binding private var text: String
    private var font: UIFont
    
    init(_ text: Binding<String>,
         font: UIFont = .preferredFont(forTextStyle: .body)) {
        _text = text
        self.font = font
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font = font
        textView.delegate = context.coordinator
        return textView
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

extension TextView {
    func font(_ font: UIFont) -> TextView {
        var view = self
        view.font = font
        return view
    }
}
