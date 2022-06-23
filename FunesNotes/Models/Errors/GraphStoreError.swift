import Foundation

enum GraphStoreError {
    case readError(error: GraphStoreReadError)
    case saveError(error: GraphStoreSaveError)
}

extension GraphStoreError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .readError(error: let error):
            return error.localizedDescription
        case .saveError(error: let error):
            return error.localizedDescription
        }
    }
}
