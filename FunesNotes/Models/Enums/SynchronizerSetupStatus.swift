import Foundation

enum SynchronizerSetupStatus {
    case ready
    case synchronizing
    case setupComplete
}

extension SynchronizerSetupStatus {
    var actionText: String {
        switch self {
        case .ready:
            return ""
        case .synchronizing:
            return "Synchronizing notes with your ship..."
        case .setupComplete:
            return ""
        }
    }
}
