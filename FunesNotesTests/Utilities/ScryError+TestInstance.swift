import Foundation
import SwiftGraphStore

extension ScryError {
    static var testInstance: ScryError {
        ScryError.scryFailed(message: UUID().uuidString)
    }
}
