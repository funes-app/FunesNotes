import Foundation
import SwiftGraphStore
import UrsusHTTP

enum ConnectionError: LocalizedError {
    case loginFailure(error: LoginError)
    case connectFailure(error: ConnectError)
    case startSubscriptionFailure(error: StartSubscriptionError)
    case readGraphStoreFailure(error: GraphStoreReadError)
    case createGraphFailure(error: GraphStoreSaveError)
    case createRootNodeFailure(error: GraphStoreSaveError)
    
    public var errorDescription: String? {
        switch self {
        case .loginFailure(let error):
            return error.localizedDescription
        case .connectFailure(let error):
            return error.localizedDescription
        case .startSubscriptionFailure(let error):
            return error.localizedDescription
        case .readGraphStoreFailure(let error):
            return error.localizedDescription
        case .createGraphFailure(error: let error):
            return error.localizedDescription
        case .createRootNodeFailure(error: let error):
            return error.localizedDescription
        }
    }
}
