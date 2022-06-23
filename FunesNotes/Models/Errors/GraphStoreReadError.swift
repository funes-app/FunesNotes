import Foundation
import SwiftGraphStore

enum GraphStoreReadError: LocalizedError {
    case notLoggedIn
    case notFound(resource: Resource, index: Index)
    case invalidResponse(update: GraphUpdate?)
    case readFailure(error: ScryError)
    
    public var errorDescription: String? {
        switch self {
        case .notLoggedIn:
            return "You aren't logged in!"
        case let .notFound(_, index):
            return "I couldn't find anything at \(index.path)"
        case let .invalidResponse(update):
            if let update = update {
                return "Unexpected response: \(update)"
            } else {
                return "Invalid response from your ship"
            }
        case let .readFailure(error):
            return error.errorDescription
        }
    }
}

extension GraphStoreReadError {
    static func fromScryError(scryError: ScryError, resource: Resource, index: Index) -> GraphStoreReadError {
        switch scryError {
        case .notLoggedIn:
            return .notLoggedIn
        case .resourceNotFound:
            return .notFound(resource: resource, index: index)
        case .scryFailed:
            return readFailure(error: scryError)
        }
    }
}
