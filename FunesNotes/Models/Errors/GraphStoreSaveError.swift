import Foundation
import UrsusHTTP
import SwiftGraphStore

enum GraphStoreSaveError: LocalizedError {
    case notLoggedIn
    case createGraphFailure(resource: Resource, error: PokeError)
    case saveFailure(error: PokeError)
    case graphStoreVersionIsNewer(graphStoreLastModified: Date)
    
    public var errorDescription: String? {
        switch self {
        case .notLoggedIn:
            return "You aren't logged in!"
        case let .createGraphFailure(resource, error):
            return "Unable to create graph \(resource):" +
            (error.errorDescription ?? "")
        case let .saveFailure(error):
            return error.errorDescription
        case let .graphStoreVersionIsNewer(graphStoreLastModified):
            return "The verison on your ship is newer, last modified on \(graphStoreLastModified)"
        }
    }
}
