import Foundation
import SwiftUI

struct TextView: View {
    @Binding private var text: String
    var font: UIFont = .preferredFont(forTextStyle: .body)
    
    init(_ text: Binding<String>) {
        _text = text
    }
    
    var body: some View {
        Representable(text: $text,
                      font: font)
    }
}

extension TextView {
    struct Representable: UIViewRepresentable {
        @Binding var text: String
        private let font: UIFont
        
        init(text: Binding<String>,
             font: UIFont) {
            _text = text
            self.font = font
        }
        
        func makeUIView(context: Context) -> UITextView {
            let view = UITextView()
            view.font = font
            view.delegate = context.coordinator
            return view
        }

        func updateUIView(_ view: UITextView, context: Context) {
            view.text = text
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(text: $text)
        }
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
