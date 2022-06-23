import Foundation
import UrsusHTTP

extension PokeError {
    static var testInstance: PokeError {
        PokeError.pokeFailure(UUID().uuidString)
    }
}
