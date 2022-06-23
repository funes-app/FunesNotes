import Foundation
import SwiftGraphStore

struct NoteId {
    private let value: Atom
    
    init(_ value: Atom) {
        self.value = value
    }
    
    init?(_ value: String) {
        guard let value = Atom(value) else {
            return nil
        }
        self.value = value
    }
}

extension NoteId {
    init(date: Date) {
        self.init(Atom(date.timeIntervalSinceReferenceDate))
    }
}

extension NoteId {
    static var empty = NoteId(0)
    
}

extension NoteId: RawRepresentable {
    var rawValue: String {
        value.description
    }
        
    init?(rawValue: String) {
        self.init(rawValue)
    }
}

extension NoteId: CustomStringConvertible {
    var description: String {
        rawValue
    }
}

extension NoteId: Equatable {}

extension NoteId: Comparable {
    static func < (lhs: NoteId, rhs: NoteId) -> Bool {
        lhs.value < rhs.value
    }
}

extension NoteId: Codable {}

extension NoteId: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}
