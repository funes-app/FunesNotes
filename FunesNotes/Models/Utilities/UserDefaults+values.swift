import Foundation

extension UserDefaults {
    var lastSelectedNoteId: NoteId? {
        get {
            guard let stringValue = string(forKey: #function) else {
                return nil
            }
            return NoteId(rawValue: stringValue)
        }
        set {
            set(newValue?.description, forKey: #function)
        }
    }
}
