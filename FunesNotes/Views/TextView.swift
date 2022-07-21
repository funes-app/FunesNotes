import Foundation
import SwiftUI
import Highlightr

struct TextView: UIViewRepresentable {
    @Binding private var text: String
    private var font: UIFont
    
    private let highlightr = Highlightr()!
        
    private static var defaultFont: UIFont {
        guard let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
            .withDesign(.monospaced)
        else {
            return .preferredFont(forTextStyle: .body)
        }
        
        return UIFont(descriptor: descriptor, size: 16)
    }
    
    init(_ text: Binding<String>,
         font: UIFont = TextView.defaultFont,
         theme: String = "dark") {
        _text = text
        self.font = font
        
        highlightr.setTheme(to: theme)
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font = font
        textView.delegate = context.coordinator
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        guard let highlightedText = highlightr.highlight(text, as: "markdown") else {
            return
        }
        let attributedText = NSMutableAttributedString(attributedString: highlightedText)
        attributedText.addAttribute(.font, value: font, range: NSRange(location: 0, length: text.count))
        textView.attributedText = attributedText
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

//extension TextView {
//    func font(_ font: UIFont) -> TextView {
//        var view = self
//        //        view.font = font
//        return view
//    }
//}
