import Foundation
import UrsusAtom
import SwiftGraphStore

extension PatP {
    static var random: PatP {
        let atom = Atom.randomInteger(withExactWidth: 32)
        return PatP(atom: atom)
    }
}
